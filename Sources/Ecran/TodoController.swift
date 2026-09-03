import AppKit
import Domain
import Infrastructure
import WindowGeometry

enum TodoController {
    @MainActor
    static func reflow(settings: AppSettings) {
        guard settings.todoMode, let bundleID = settings.todoBundleID else { return }
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }) else {
            return
        }
        let records = WindowCatalog.windows(for: app, settings: settings, excludingBundleID: nil)
        guard let record = records.first else { return }
        let application = AXUIElementCreateApplication(app.processIdentifier)
        var value: AnyObject?
        AXUIElementCopyAttributeValue(application, kAXWindowsAttribute as CFString, &value)
        guard let element = (value as? [AXUIElement])?.first(where: { WindowCatalog.windowID(for: $0) == record.windowID }),
              let frame = WindowCatalog.frame(of: element)
        else { return }
        let screen = ScreenCatalog.screen(containing: frame, settings: settings, cursor: nil)
        let usable = GapPolicy.usableFrame(for: screen, settings: settings, reserveTodo: false)
        let width = settings.todoIsFraction ? usable.width * settings.todoWidth : settings.todoWidth
        let strip = settings.todoSide == .left
            ? CGRect(x: usable.minX, y: usable.minY, width: width, height: usable.height)
            : CGRect(x: usable.maxX - width, y: usable.minY, width: width, height: usable.height)
        WindowCatalog.setFrame(strip, of: element)
    }
}
