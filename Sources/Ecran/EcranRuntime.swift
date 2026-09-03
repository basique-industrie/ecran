import AppKit
import ApplicationServices
import Domain
import Foundation
import Infrastructure
import Observation
import WindowGeometry

@MainActor
@Observable
public final class EcranRuntime {
    var settings: AppSettings
    var accessibilityTrusted = false
    var screenRecordingGranted = false
    var launchAtLoginEnabled = false
    var switcherIsOpen = false
    var frontmostBundleID: String?

    let mover = WindowMover()
    let hotkeys = HotkeyCenter()
    private let store: JSONSettingsStore
    private var permissionTimer: Timer?
    private var workspaceObserver: NSObjectProtocol?

    var onShowSameAppSwitcher: (() -> Void)?
    var onShowAppSwitcher: (() -> Void)?
    var onRepeatAppSwitcher: ((Bool) -> Void)?
    var onReleaseAppSwitcher: (() -> Void)?
    var onMenuBarVisibilityChanged: (() -> Void)?

    var isFrontmostIgnored: Bool {
        guard let frontmostBundleID else { return false }
        return settings.isIgnored(frontmostBundleID)
    }

    init(store: JSONSettingsStore = JSONSettingsStore()) {
        self.store = store
        self.settings = store.load()
        self.settings.language.applyPreferredLanguages()
        self.launchAtLoginEnabled = LaunchAtLogin.isEnabled
        self.frontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        refreshPermissions()
    }

    func start() {
        applyLaunchConfigIfPresent()
        bindHotkeys()
        reregisterHotkeys()
        observeFrontmostApp()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshPermissions()
            }
        }
        AppLog.ui.info("\(AppIdentity.current.displayName) started")
    }

    func stop() {
        permissionTimer?.invalidate()
        permissionTimer = nil
        if let workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver)
        }
        hotkeys.unregister()
    }

    func update(_ mutate: (inout AppSettings) -> Void) {
        let hideIcon = settings.hideMenuBarIcon
        mutate(&settings)
        settings.switcherVerticalPosition = settings.clampedVerticalPosition
        store.save(settings)
        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        if hideIcon != settings.hideMenuBarIcon {
            onMenuBarVisibilityChanged?()
        }
    }

    func persistAndReregisterHotkeys() {
        store.save(settings)
        reregisterHotkeys()
        NotificationCenter.default.post(name: .hotkeySettingsChanged, object: nil)
    }

    func applyImportedSettings(_ imported: AppSettings) {
        let hideIcon = settings.hideMenuBarIcon
        settings = imported
        settings.switcherVerticalPosition = settings.clampedVerticalPosition
        settings.language.applyPreferredLanguages()
        store.save(settings)
        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        reregisterHotkeys()
        NotificationCenter.default.post(name: .hotkeySettingsChanged, object: nil)
        if hideIcon != settings.hideMenuBarIcon {
            onMenuBarVisibilityChanged?()
        }
    }

    func reregisterHotkeys() {
        hotkeys.register(
            settings: settings,
            includeSwitcher: FeatureIsolation.switcherHotkeysEnabled(frontmostIgnored: isFrontmostIgnored),
            includePlacement: FeatureIsolation.placementHotkeysEnabled(
                switcherOpen: switcherIsOpen,
                frontmostIgnored: isFrontmostIgnored
            )
        )
    }

    func setSwitcherOpen(_ open: Bool, kind: SwitcherKind? = nil) {
        switcherIsOpen = open
        hotkeys.setPlacementEnabled(
            FeatureIsolation.placementHotkeysEnabled(
                switcherOpen: open,
                frontmostIgnored: isFrontmostIgnored
            )
        )
        hotkeys.setSameAppSwitcherVisible(open && kind == .sameApp)
        hotkeys.setAppSwitcherVisible(open && kind == .apps)
        if !open {
            hotkeys.setSameAppSwitcherVisible(false)
            hotkeys.setAppSwitcherVisible(false)
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginEnabled = LaunchAtLogin.setEnabled(enabled)
        update { $0.launchAtLogin = launchAtLoginEnabled }
    }

    func execute(_ action: WindowAction, source: ActionSource = .hotkey, element: AXUIElement? = nil) {
        guard accessibilityTrusted else {
            AccessibilityAuthorization.request()
            return
        }
        if source == .hotkey, isFrontmostIgnored {
            return
        }
        if (source == .titleBar || source == .greenButton), shouldRestoreInstead(of: action, element: element) {
            _ = mover.execute(.restore, settings: settings, element: element)
            return
        }
        _ = mover.execute(action, settings: settings, element: element)
        TodoController.reflow(settings: settings)
    }

    func executeCycle(_ actions: [WindowAction]) {
        guard accessibilityTrusted else {
            AccessibilityAuthorization.request()
            return
        }
        if isFrontmostIgnored { return }
        _ = mover.executeCycle(actions, settings: settings)
        TodoController.reflow(settings: settings)
    }

    func toggleIgnoreFrontmostApp() {
        guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return }
        update { $0.toggleIgnored(bundleID) }
        persistAndReregisterHotkeys()
    }

    func handle(_ command: URLCommand) {
        switch command.kind {
        case .settings:
            return
        case .action(let action):
            execute(action, source: .url)
        case .task(let task, let bundleID):
            let identifier = bundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
            guard let identifier else { return }
            update { settings in
                switch task {
                case .ignoreApp:
                    if !settings.ignoredBundleIDs.contains(identifier) {
                        settings.ignoredBundleIDs.append(identifier)
                    }
                case .unignoreApp:
                    settings.ignoredBundleIDs.removeAll { $0 == identifier }
                }
            }
            persistAndReregisterHotkeys()
        }
    }

    func confirmURLTaskIfNeeded() -> Bool {
        if NSWorkspace.shared.frontmostApplication == NSRunningApplication.current {
            return true
        }
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Allow Ecran URL task?"
        alert.informativeText = "A URL asked Ecran to ignore or unignore an app."
        alert.addButton(withTitle: "Allow")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    func refreshPermissions() {
        accessibilityTrusted = AccessibilityAuthorization.isTrusted
        screenRecordingGranted = AccessibilityAuthorization.hasScreenRecording
    }

    func snapIsEnabled() -> Bool {
        FeatureIsolation.snapEnabled(
            windowSnapping: settings.windowSnapping,
            ignoreDragSnapToo: settings.ignoreDragSnapToo,
            switcherOpen: switcherIsOpen,
            frontmostIgnored: isFrontmostIgnored
        )
    }

    private func shouldRestoreInstead(of action: WindowAction, element: AXUIElement?) -> Bool {
        let target = element ?? WindowCatalog.focusedWindowElement()
        guard let target, let frame = WindowCatalog.frame(of: target) else { return false }
        let windowID = WindowCatalog.windowID(for: target)
        return TitleBarRestore.shouldRestore(
            enabled: settings.doubleClickTitleBarRestore,
            action: action,
            historyMatches: mover.windowHistory.matchesLastRectangle(windowID, frame: frame),
            lastAction: mover.windowHistory.lastAction(for: windowID)?.action
        )
    }

    private func applyLaunchConfigIfPresent() {
        let url = AppIdentity.current.dataDirectory.appendingPathComponent("EcranConfig.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        if let permissions = attributes?[.posixPermissions] as? NSNumber, permissions.intValue & 0o002 != 0 {
            AppLog.ui.error("Ignored world-writable launch config")
            return
        }
        guard let data = try? Data(contentsOf: url),
              let imported = try? ConfigImportExport.importSettings(from: data, into: settings, titlesOnly: false)
        else { return }
        applyImportedSettings(imported)
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let archived = url.deletingLastPathComponent().appendingPathComponent("EcranConfig-\(stamp).json")
        try? FileManager.default.moveItem(at: url, to: archived)
        AppLog.ui.info("Applied launch configuration")
    }

    private func observeFrontmostApp() {
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            Task { @MainActor in
                guard let self else { return }
                let previousIgnored = self.isFrontmostIgnored
                self.frontmostBundleID = app?.bundleIdentifier
                if previousIgnored != self.isFrontmostIgnored {
                    self.hotkeys.setPlacementEnabled(
                        FeatureIsolation.placementHotkeysEnabled(
                            switcherOpen: self.switcherIsOpen,
                            frontmostIgnored: self.isFrontmostIgnored
                        )
                    )
                }
            }
        }
    }

    private func bindHotkeys() {
        hotkeys.onSameAppSwitcher = { [weak self] in
            self?.onShowSameAppSwitcher?()
        }
        hotkeys.onAppSwitcher = { [weak self] in
            self?.onShowAppSwitcher?()
        }
        hotkeys.onAppSwitcherRepeat = { [weak self] reverse in
            self?.onRepeatAppSwitcher?(reverse)
        }
        hotkeys.onAppSwitcherReleased = { [weak self] in
            self?.onReleaseAppSwitcher?()
        }
        hotkeys.onWindowAction = { [weak self] action in
            self?.execute(action, source: .hotkey)
        }
        hotkeys.onWindowActionCycle = { [weak self] actions in
            self?.executeCycle(actions)
        }
    }
}
