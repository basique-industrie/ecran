import ApplicationServices
import Foundation
#if canImport(AppKit)
import AppKit
#endif

public enum PermissionPane: String, Sendable, CaseIterable {
    case accessibility
    case screenRecording

    public var systemSettingsURLs: [String] {
        switch self {
        case .accessibility:
            [
                "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            ]
        case .screenRecording:
            [
                "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture",
                "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture",
            ]
        }
    }
}

public enum ScreenRecordingAccess: Equatable, Sendable {
    case notGranted
    case granted
    case grantedPendingRelaunch

    public static func resolve(preflight: Bool, hadCaptureAtLaunch: Bool) -> ScreenRecordingAccess {
        if !preflight { return .notGranted }
        return hadCaptureAtLaunch ? .granted : .grantedPendingRelaunch
    }

    public var isGranted: Bool {
        self != .notGranted
    }

    public var needsRelaunch: Bool {
        self == .grantedPendingRelaunch
    }
}

public enum PermissionPolling: Sendable {
    public static let fast: TimeInterval = 0.6
    public static let idle: TimeInterval = 2

    public static func interval(
        accessibilityTrusted: Bool,
        watchingGrant: Bool,
        screenRecordingGranted: Bool,
        needsRelaunch: Bool
    ) -> TimeInterval {
        if !accessibilityTrusted { return fast }
        if needsRelaunch { return fast }
        if watchingGrant { return fast }
        return idle
    }

    public static func isWatching(
        accessibilityTrusted: Bool,
        watchingAccessibility: Bool,
        screenRecordingReady: Bool,
        watchingScreenRecording: Bool
    ) -> Bool {
        if watchingAccessibility, !accessibilityTrusted { return true }
        if watchingScreenRecording, !screenRecordingReady { return true }
        return false
    }
}

/// macOS only shows the Accessibility / Screen Recording system prompt, then
/// the user has to flip the toggle in System Settings. Codex and other current
/// Mac apps do three things in order: explain in-app, request while frontmost
/// (so TCC actually creates a row), then open the matching Settings pane.
@MainActor
public enum AccessibilityAuthorization {
    public static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    public static var hasScreenRecording: Bool {
        // Only this process's Screen Recording grant. Window-list titles are
        // also visible with Accessibility, so they must not be used as a probe.
        CGPreflightScreenCaptureAccess()
    }

    public static func requestWhileFrontmost() {
        activateForPermissionPrompt()
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let options = [promptKey: kCFBooleanTrue] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    public static func grantAccessibility() {
        requestWhileFrontmost()
        openSystemSettings(.accessibility)
    }

    public static func requestScreenRecording() {
        activateForPermissionPrompt()
        _ = CGRequestScreenCaptureAccess()
    }

    public static func grantScreenRecording() {
        requestScreenRecording()
        openSystemSettings(.screenRecording)
    }

    public static func openSystemSettings(_ pane: PermissionPane = .accessibility) {
        #if canImport(AppKit)
        for raw in pane.systemSettingsURLs {
            if let url = URL(string: raw), NSWorkspace.shared.open(url) {
                return
            }
        }
        #endif
    }

    public static func relaunch(arguments: [String] = ["--open-settings"]) {
        #if canImport(AppKit)
        let appPath = Bundle.main.bundleURL.path
        let pid = ProcessInfo.processInfo.processIdentifier
        var command = "while /bin/kill -0 \(pid) 2>/dev/null; do /bin/sleep 0.05; done; /usr/bin/open \(shellEscape(appPath))"
        if !arguments.isEmpty {
            command += " --args"
            for argument in arguments {
                command += " \(shellEscape(argument))"
            }
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", "(\n\(command)\n) >/dev/null 2>&1 &"]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return
        }
        NSApp.terminate(nil)
        #endif
    }

    public static func shellEscape(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// Drops this Dev bundle's TCC rows so Grant can be tried again, and
    /// refreshes Launch Services / Icon Services so System Settings picks up
    /// the current mark instead of the icon cached on the first grant.
    @discardableResult
    public static func resetDevelopmentGrants() -> Bool {
        guard AppIdentity.current.isDevelopment else { return false }
        let identifier = AppIdentity.development.bundleIdentifier
        _ = run("/usr/bin/tccutil", ["reset", "Accessibility", identifier])
        _ = run("/usr/bin/tccutil", ["reset", "ScreenCapture", identifier])
        refreshDevelopmentIconRegistration()
        return true
    }

    public static func refreshDevelopmentIconRegistration() {
        let app = Bundle.main.bundleURL.path
        let lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
        _ = run(lsregister, ["-f", "-R", app])
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: app)
        _ = run("/usr/bin/killall", ["-u", NSUserName(), "iconservicesagent"])
    }

    private static func activateForPermissionPrompt() {
        #if canImport(AppKit)
        NSApp.activate(ignoringOtherApps: true)
        #endif
    }

    @discardableResult
    private static func run(_ launchPath: String, _ arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
