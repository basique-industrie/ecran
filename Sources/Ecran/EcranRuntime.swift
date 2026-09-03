import AppKit
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
    var screenRecordingNeedsRelaunch = false
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
    var onNeedsAccessibility: (() -> Void)?
    private var hadScreenRecordingAtLaunch: Bool?
    private var watchingAccessibilityGrant = false
    private var watchingScreenRecordingGrant = false

    var isFrontmostIgnored: Bool {
        let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? frontmostBundleID
        guard let bundleID else { return false }
        return settings.isIgnored(bundleID)
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
        startPermissionPolling(interval: permissionPollInterval)
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
            ensureAccessibility()
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
            ensureAccessibility()
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

    func confirmURLCommandIfNeeded(_ command: URLCommand) -> Bool {
        guard URLCommandConfirmation.requiresPrompt(command.kind, confirmActions: settings.confirmURLActions) else {
            return true
        }
        switch command.kind {
        case .task:
            return confirmURLCommand(
                title: "Allow Ecran URL task?",
                detail: "A URL asked Ecran to ignore or unignore an app."
            )
        case .action:
            return confirmURLCommand(
                title: "Allow Ecran URL action?",
                detail: "A URL asked Ecran to move or resize a window."
            )
        case .settings:
            return true
        }
    }

    private func confirmURLCommand(title: String, detail: String) -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = detail
        alert.addButton(withTitle: "Allow")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    func refreshPermissions() {
        let wasTrusted = accessibilityTrusted
        accessibilityTrusted = AccessibilityAuthorization.isTrusted
        let recording = AccessibilityAuthorization.hasScreenRecording
        if hadScreenRecordingAtLaunch == nil {
            hadScreenRecordingAtLaunch = recording
        }
        let access = ScreenRecordingAccess.resolve(
            preflight: recording,
            hadCaptureAtLaunch: hadScreenRecordingAtLaunch ?? recording
        )
        screenRecordingGranted = access.isGranted
        screenRecordingNeedsRelaunch = access.needsRelaunch
        if accessibilityTrusted {
            watchingAccessibilityGrant = false
        }
        if screenRecordingGranted, !screenRecordingNeedsRelaunch {
            watchingScreenRecordingGrant = false
        }
        if wasTrusted != accessibilityTrusted {
            NotificationCenter.default.post(name: .permissionsDidChange, object: nil)
        }
        if permissionTimer != nil {
            startPermissionPolling(interval: permissionPollInterval)
        }
    }

    func ensureAccessibility() {
        guard !accessibilityTrusted else { return }
        AccessibilityAuthorization.requestWhileFrontmost()
        watchingAccessibilityGrant = true
        watchPermissionChanges()
        onNeedsAccessibility?()
    }

    func grantAccessibility() {
        watchingAccessibilityGrant = true
        AccessibilityAuthorization.grantAccessibility()
        watchPermissionChanges()
    }

    func grantScreenRecording() {
        watchingScreenRecordingGrant = true
        AccessibilityAuthorization.grantScreenRecording()
        watchPermissionChanges()
    }

    func resetDevelopmentPermissions() {
        _ = AccessibilityAuthorization.resetDevelopmentGrants()
        AccessibilityAuthorization.relaunch()
    }

    func watchPermissionChanges() {
        if !accessibilityTrusted {
            watchingAccessibilityGrant = true
        }
        startPermissionPolling(interval: PermissionPolling.fast)
    }

    private var watchingPermissionGrant: Bool {
        PermissionPolling.isWatching(
            accessibilityTrusted: accessibilityTrusted,
            watchingAccessibility: watchingAccessibilityGrant,
            screenRecordingReady: screenRecordingGranted && !screenRecordingNeedsRelaunch,
            watchingScreenRecording: watchingScreenRecordingGrant
        )
    }

    private var permissionPollInterval: TimeInterval {
        PermissionPolling.interval(
            accessibilityTrusted: accessibilityTrusted,
            watchingGrant: watchingPermissionGrant,
            screenRecordingGranted: screenRecordingGranted,
            needsRelaunch: screenRecordingNeedsRelaunch
        )
    }

    private func startPermissionPolling(interval: TimeInterval) {
        if permissionTimer?.timeInterval == interval, permissionTimer?.isValid == true {
            return
        }
        permissionTimer?.invalidate()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            MainThreadHop.run {
                self?.refreshPermissions()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        permissionTimer = timer
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
        do {
            let data = try SettingsFilePolicy.readJSON(at: url)
            let imported = try ConfigImportExport.importSettings(from: data, into: settings, titlesOnly: false)
            applyImportedSettings(imported)
            let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let archived = url.deletingLastPathComponent().appendingPathComponent("EcranConfig-\(stamp).json")
            try? FileManager.default.moveItem(at: url, to: archived)
            AppLog.ui.info("Applied launch configuration")
        } catch {
            AppLog.ui.error("Ignored launch config: \(error.localizedDescription)")
        }
    }

    private func observeFrontmostApp() {
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            MainThreadHop.run {
                guard let self else { return }
                let previousIgnored = self.frontmostBundleID.map { self.settings.isIgnored($0) } ?? false
                self.frontmostBundleID = app?.bundleIdentifier
                    ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
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
