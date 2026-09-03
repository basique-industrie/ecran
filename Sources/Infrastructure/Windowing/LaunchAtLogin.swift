import Foundation
import ServiceManagement

public enum LaunchAtLogin {
    public static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    public static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            AppLog.ui.info("Launch at login \(enabled ? "enabled" : "disabled")")
        } catch {
            AppLog.ui.error("Launch at login failed: \(error.localizedDescription)")
        }
        return isEnabled
    }
}
