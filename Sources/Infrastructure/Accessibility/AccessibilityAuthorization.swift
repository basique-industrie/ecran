import ApplicationServices
import Foundation
#if canImport(AppKit)
import AppKit
#endif

public enum AccessibilityAuthorization {
    public static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    public static func request() {
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let options = [promptKey: kCFBooleanTrue] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    public static func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility") else {
            return
        }
        #if canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }

    public static var hasScreenRecording: Bool {
        CGPreflightScreenCaptureAccess()
    }

    public static func requestScreenRecording() {
        _ = CGRequestScreenCaptureAccess()
    }
}
