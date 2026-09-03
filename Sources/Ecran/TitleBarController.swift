import AppKit
import Domain
import Infrastructure

@MainActor
final class TitleBarController {
    private let runtime: EcranRuntime
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var lastEventNumber: Int = -1

    init(runtime: EcranRuntime) {
        self.runtime = runtime
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            MainThreadHop.run {
                self?.handle(event)
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    private func handle(_ event: NSEvent) {
        guard let action = runtime.settings.doubleClickTitleBarAction else { return }
        guard runtime.accessibilityTrusted, event.clickCount == 2 else { return }
        guard event.eventNumber != lastEventNumber else { return }
        lastEventNumber = event.eventNumber
        let location = ScreenCatalog.cocoaToAccessibility(NSEvent.mouseLocation)
        guard let hit = WindowCatalog.element(at: location),
              let window = WindowCatalog.windowElement(containing: hit),
              let titleBar = WindowCatalog.titleBarFrame(of: window),
              titleBar.contains(location)
        else { return }
        runtime.execute(action, source: .titleBar, element: window)
    }
}
