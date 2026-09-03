import AppKit
import Domain
import Infrastructure
import SwiftUI

@MainActor
final class SwitcherController {
    private let runtime: EcranRuntime
    private var panel: SwitcherPanel?
    private var model: SwitcherModel?
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var watchdog: Timer?
    private var openedAt = Date()
    private var held = false
    private var lastOpen = Date.distantPast
    private var modifierArmed = false
    private var lastModifierEvent = Date.distantPast

    init(runtime: EcranRuntime) {
        self.runtime = runtime
        runtime.onShowSameAppSwitcher = { [weak self] in self?.show(.sameApp) }
        runtime.onShowAppSwitcher = { [weak self] in self?.show(.apps) }
        runtime.onRepeatAppSwitcher = { [weak self] reverse in self?.advance(reverse: reverse) }
        runtime.onReleaseAppSwitcher = { [weak self] in
            guard self?.model?.kind == .apps else { return }
            self?.dismiss(activate: true)
        }
    }

    func show(_ kind: SwitcherKind) {
        guard runtime.accessibilityTrusted else {
            AccessibilityAuthorization.request()
            runtime.setSwitcherOpen(false)
            return
        }
        if panel != nil {
            if model?.kind == kind {
                advance(reverse: NSEvent.modifierFlags.contains(.shift))
                return
            }
            dismiss(activate: false)
        }
        if runtime.settings.doubleTapToHold, Date().timeIntervalSince(lastOpen) < 0.35 {
            held = true
        }
        lastOpen = Date()
        openedAt = Date()
        modifierArmed = NSEvent.modifierFlags.contains(requiredModifier(for: kind))
        let model = SwitcherModel(kind: kind, runtime: runtime) { [weak self] in
            self?.dismiss(activate: true)
        }
        model.reload()
        if model.items.isEmpty {
            AppLog.switcher.info("No \(kind == .sameApp ? "windows" : "apps") to switch")
            runtime.setSwitcherOpen(false)
            return
        }
        let livePIDs: Set<pid_t>
        switch kind {
        case .sameApp:
            livePIDs = Set(model.windows.map(\.processID))
        case .apps:
            livePIDs = Set(model.apps.map(\.processID))
        }
        AppIconCache.shared.evict(keeping: livePIDs)
        let panel = SwitcherPanel.make(followAcrossDesktops: runtime.settings.followAcrossDesktops)
        let host = NSHostingView(rootView: SwitcherView(model: model, settings: runtime.settings))
        host.sizingOptions = []
        host.frame = NSRect(origin: .zero, size: SwitcherPanel.metrics)
        host.wantsLayer = true
        host.layer?.backgroundColor = NSColor.clear.cgColor
        host.layer?.cornerRadius = 16
        host.layer?.cornerCurve = .continuous
        host.layer?.masksToBounds = true
        panel.contentView = host
        panel.setContentSize(SwitcherPanel.metrics)
        position(panel)
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
        self.model = model
        runtime.setSwitcherOpen(true, kind: kind)
        model.loadPreviewsIfNeeded()
        AppLog.switcher.info("Opened \(kind == .sameApp ? "same-app" : "app") switcher (\(model.items.count))")
        modifierArmed = NSEvent.modifierFlags.contains(requiredModifier(for: kind))
        if SwitcherHold.shouldDismissOnShow(modifierDown: modifierArmed, held: held) {
            dismiss(activate: true)
            return
        }
        startMonitors(model: model)
    }

    func dismiss(activate: Bool) {
        guard panel != nil || model != nil else { return }
        watchdog?.invalidate()
        watchdog = nil
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        localMonitor = nil
        globalMonitor = nil
        runtime.setSwitcherOpen(false)
        let target = model
        let closing = panel
        panel = nil
        model = nil
        held = false
        modifierArmed = false
        target?.cancelPreviews()
        // A fullScreenAuxiliary panel pins the current fullscreen Space.
        // Hide it before focusing so Ghostty (and others) can leave that Space.
        closing?.orderOut(nil)
        if activate {
            target?.activateSelection()
        }
    }

    private func advance(reverse: Bool) {
        guard let model else {
            show(.apps)
            return
        }
        model.move(reverse ? -1 : 1)
    }

    private func position(_ panel: NSPanel) {
        let screen: NSScreen?
        if runtime.settings.switcherFollowActiveWindow {
            screen = ScreenCatalog.screenContainingActiveWindow()
        } else {
            screen = ScreenCatalog.primaryScreen()
        }
        let frame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let size = SwitcherPanel.metrics
        let x = frame.midX - size.width / 2
        let y = frame.maxY - (frame.height * runtime.settings.clampedVerticalPosition) - size.height / 2
        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
    }

    private func startMonitors(model: SwitcherModel) {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            self?.handle(event, model: model)
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            _ = self?.handle(event, model: model)
        }
        watchdog = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            timer.tolerance = 0.02
            Task { @MainActor in
                self?.pollModifiers(model: model)
            }
        }
    }

    private func handle(_ event: NSEvent, model: SwitcherModel) -> NSEvent? {
        if event.type == .flagsChanged {
            let now = Date()
            if now.timeIntervalSince(lastModifierEvent) < 0.05 {
                return event
            }
            lastModifierEvent = now
            pollModifiers(model: model)
            return event
        }
        if event.type == .keyDown {
            let trigger = model.kind == .sameApp
                ? runtime.settings.triggerKey.keyCode
                : runtime.settings.appSwitcherTriggerKey.keyCode
            if event.keyCode == UInt16(trigger),
               event.modifierFlags.contains(requiredModifier(for: model.kind))
            {
                if runtime.settings.doubleTapToHold, !held, Date().timeIntervalSince(openedAt) < 0.35 {
                    held = true
                }
                advance(reverse: event.modifierFlags.contains(.shift))
                return nil
            }
            switch event.keyCode {
            case 125:
                model.move(1)
                return nil
            case 126:
                model.move(-1)
                return nil
            case 36, 76:
                dismiss(activate: true)
                return nil
            case 53:
                dismiss(activate: false)
                return nil
            case 18, 19, 20, 21, 23, 22, 26, 28, 25:
                let map: [UInt16: Int] = [18: 0, 19: 1, 20: 2, 21: 3, 23: 4, 22: 5, 26: 6, 28: 7, 25: 8]
                if runtime.settings.showNumberKeys, let index = map[event.keyCode] {
                    model.select(index)
                    dismiss(activate: true)
                    return nil
                }
            default:
                break
            }
        }
        return event
    }

    private func pollModifiers(model: SwitcherModel) {
        guard panel != nil else { return }
        let required = requiredModifier(for: model.kind)
        if NSEvent.modifierFlags.contains(required) {
            modifierArmed = true
            return
        }
        guard modifierArmed, !held else { return }
        dismiss(activate: true)
    }

    private func requiredModifier(for kind: SwitcherKind) -> NSEvent.ModifierFlags {
        let key = kind == .sameApp ? runtime.settings.modifierKey : runtime.settings.appSwitcherModifierKey
        return NSEvent.ModifierFlags(rawValue: key.eventModifierRawValue)
    }
}

final class SwitcherPanel: NSPanel {
    static let metrics = NSSize(width: 600, height: 400)

    static func make(followAcrossDesktops: Bool = true) -> SwitcherPanel {
        let panel = SwitcherPanel(
            contentRect: NSRect(origin: .zero, size: metrics),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        var behavior: NSWindow.CollectionBehavior = [.fullScreenAuxiliary, .stationary, .ignoresCycle]
        if followAcrossDesktops {
            behavior.insert(.canJoinAllSpaces)
        }
        panel.collectionBehavior = behavior
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        return panel
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
@Observable
final class SwitcherModel {
    let kind: SwitcherKind
    private let runtime: EcranRuntime
    private let onActivate: () -> Void
    var windows: [WindowRecord] = []
    var apps: [AppRecord] = []
    var selection = 0
    var previews: [UInt32: NSImage] = [:]
    private var previewTask: Task<Void, Never>?

    var items: [String] {
        switch kind {
        case .sameApp: windows.map(\.projectName)
        case .apps: apps.map(\.appName)
        }
    }

    init(kind: SwitcherKind, runtime: EcranRuntime, onActivate: @escaping () -> Void) {
        self.kind = kind
        self.runtime = runtime
        self.onActivate = onActivate
    }

    func reload() {
        let excluding = Bundle.main.bundleIdentifier
        switch kind {
        case .sameApp:
            windows = WindowCatalog.sameAppWindows(settings: runtime.settings, excludingBundleID: excluding)
            selection = windows.count > 1 ? 1 : 0
        case .apps:
            apps = WindowCatalog.runningRegularApps(settings: runtime.settings, excludingBundleID: excluding)
            selection = apps.count > 1 ? 1 : 0
        }
    }

    func loadPreviewsIfNeeded() {
        previewTask?.cancel()
        guard kind == .sameApp,
              runtime.settings.windowDisplayStyle == .preview,
              runtime.screenRecordingGranted
        else { return }
        let snapshot = windows
        previewTask = Task.detached { [weak self] in
            for window in snapshot where window.windowID != 0 {
                if Task.isCancelled { return }
                guard let image = WindowCatalog.previewImage(for: window.windowID) else { continue }
                await MainActor.run {
                    self?.previews[window.windowID] = image
                }
            }
        }
    }

    func cancelPreviews() {
        previewTask?.cancel()
        previewTask = nil
    }

    func move(_ delta: Int) {
        let count = max(items.count, 1)
        selection = (selection + delta + count) % count
    }

    func select(_ index: Int) {
        guard items.indices.contains(index) else { return }
        selection = index
    }

    func activateSelection() {
        switch kind {
        case .sameApp:
            guard windows.indices.contains(selection) else { return }
            WindowCatalog.activate(window: windows[selection])
        case .apps:
            guard apps.indices.contains(selection) else { return }
            WindowCatalog.activate(app: apps[selection])
        }
    }

    func choose(_ index: Int) {
        select(index)
        onActivate()
    }
}
