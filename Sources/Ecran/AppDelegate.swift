import AppKit
import CoreServices
import Domain
import Infrastructure
import SwiftUI

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var runtime: EcranRuntime?
    private var settingsController: SettingsController?
    private var switcherController: SwitcherController?
    private var snapController: SnapController?
    private var titleBarController: TitleBarController?
    private var greenButtonController: GreenButtonController?
    private var statusMenu: StatusMenuController?
    private var openSettingsObserver: NSObjectProtocol?

    public var launchesAtLogin: Bool {
        runtime?.launchAtLoginEnabled ?? LaunchAtLogin.isEnabled
    }

    public var hidesMenuBarIcon: Bool {
        runtime?.settings.hideMenuBarIcon ?? false
    }

    public var showsAdditionalSizes: Bool {
        runtime?.settings.showAdditionalSizesInMenu ?? false
    }

    public var showsTodoActions: Bool {
        runtime?.settings.todoMode ?? false
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        ProcessInfo.processInfo.disableSuddenTermination()
        if Self.activateExistingInstanceIfNeeded() {
            NSApp.terminate(nil)
            return
        }
        let runtime = EcranRuntime()
        self.runtime = runtime
        settingsController = SettingsController(runtime: runtime)
        switcherController = SwitcherController(runtime: runtime)
        snapController = SnapController(runtime: runtime)
        titleBarController = TitleBarController(runtime: runtime)
        greenButtonController = GreenButtonController(runtime: runtime)
        runtime.onNeedsAccessibility = { [weak self] in
            self?.showSettings()
        }
        runtime.start()
        statusMenu = StatusMenuController(runtime: runtime) { [weak self] in
            self?.showSettings()
        }
        MenuBarIdentityIcon.applyDevelopmentTintIfNeeded()
        observeOpenSettings()
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
        if CommandLine.arguments.contains("--open-settings") || !runtime.accessibilityTrusted {
            showSettings()
        }
        if !runtime.accessibilityTrusted {
            AccessibilityAuthorization.requestWhileFrontmost()
            runtime.watchPermissionChanges()
        }
    }

    public func applicationWillTerminate(_ notification: Notification) {
        if let openSettingsObserver {
            DistributedNotificationCenter.default().removeObserver(openSettingsObserver)
        }
        openSettingsObserver = nil
        runtime?.stop()
        snapController?.stop()
        titleBarController?.stop()
        greenButtonController?.stop()
        statusMenu?.invalidate()
        statusMenu = nil
        settingsController?.invalidate()
        MenuBarIdentityIcon.invalidate()
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    public func showSettings() {
        settingsController?.show()
    }

    public func setLaunchAtLogin(_ enabled: Bool) {
        runtime?.setLaunchAtLogin(enabled)
    }

    public func setHideMenuBarIcon(_ hidden: Bool) {
        runtime?.update { $0.hideMenuBarIcon = hidden }
    }

    public func execute(_ action: WindowAction) {
        runtime?.execute(action, source: .menu)
    }

    public func toggleIgnoreFrontmostApp() {
        runtime?.toggleIgnoreFrontmostApp()
    }

    @objc private func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        guard let string = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: string),
              let command = URLCommand.parse(url: url)
        else { return }
        if case .settings = command.kind {
            showSettings()
            return
        }
        if runtime?.confirmURLCommandIfNeeded(command) != true {
            return
        }
        runtime?.handle(command)
    }

    private func observeOpenSettings() {
        let name = AppIdentity.current.openSettingsNotification
        openSettingsObserver = DistributedNotificationCenter.default().addObserver(
            forName: name,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainThreadHop.run {
                self?.showSettings()
            }
        }
    }

    private static func activateExistingInstanceIfNeeded() -> Bool {
        let identifier = Bundle.main.bundleIdentifier ?? AppIdentity.shippedBundleIdentifier
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        guard let existing = others.first else { return false }
        if CommandLine.arguments.contains("--open-settings") {
            DistributedNotificationCenter.default().post(
                name: AppIdentity.current.openSettingsNotification,
                object: identifier
            )
        }
        existing.activate()
        return true
    }
}
