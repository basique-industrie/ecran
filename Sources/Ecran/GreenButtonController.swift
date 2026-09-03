import AppKit
import ApplicationServices
import Domain
import Infrastructure

@MainActor
final class GreenButtonController {
    private let runtime: EcranRuntime
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let state = GreenButtonState()

    init(runtime: EcranRuntime) {
        self.runtime = runtime
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: .settingsDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: .permissionsDidChange,
            object: nil
        )
        refresh()
    }

    func stop() {
        NotificationCenter.default.removeObserver(self)
        stopTap()
    }

    @objc private func settingsChanged() {
        refresh()
    }

    private func refresh() {
        state.enabled = runtime.settings.greenButtonOverride && runtime.accessibilityTrusted
        if state.enabled {
            startTap()
        } else {
            stopTap()
        }
    }

    private func startTap() {
        guard eventTap == nil else { return }
        let mask = (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.leftMouseUp.rawValue)
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, userData in
                guard let userData else { return Unmanaged.passUnretained(event) }
                let controller = Unmanaged<GreenButtonController>.fromOpaque(userData).takeUnretainedValue()
                return controller.handleTap(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        guard let eventTap else { return }
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        CGEvent.tapEnable(tap: eventTap, enable: true)
        state.setPort(eventTap)
    }

    private func stopTap() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        state.setPort(nil)
        state.clear()
    }

    nonisolated private func handleTap(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let port = state.port {
                CGEvent.tapEnable(tap: port, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        guard state.enabled else { return Unmanaged.passUnretained(event) }
        let location = event.location
        if type == .leftMouseDown, consumeMouseDown(at: location) {
            return nil
        }
        if type == .leftMouseUp, state.hasArmedButton {
            let armed = state.buttonFrame
            let window = state.armedWindow
            state.clear()
            if let armed, armed.contains(location) {
                Task { @MainActor in
                    runtime.execute(.maximize, source: .greenButton, element: window)
                }
            }
        }
        return Unmanaged.passUnretained(event)
    }

    nonisolated private func consumeMouseDown(at location: CGPoint) -> Bool {
        guard let element = WindowCatalog.element(at: location),
              WindowCatalog.isFullScreenButton(element),
              let frame = WindowCatalog.frame(of: element)
        else {
            state.clear()
            return false
        }
        state.arm(frame, window: WindowCatalog.windowElement(containing: element))
        return true
    }
}

private final class GreenButtonState: @unchecked Sendable {
    private let lock = NSLock()
    private var enabledValue = false
    private var frame: CGRect?
    private var window: AXUIElement?
    private var portValue: CFMachPort?

    var enabled: Bool {
        get { lock.withLock { enabledValue } }
        set { lock.withLock { enabledValue = newValue } }
    }

    var hasArmedButton: Bool {
        lock.withLock { frame != nil }
    }

    var buttonFrame: CGRect? {
        lock.withLock { frame }
    }

    var armedWindow: AXUIElement? {
        lock.withLock { window }
    }

    var port: CFMachPort? {
        lock.withLock { portValue }
    }

    func arm(_ rect: CGRect, window: AXUIElement?) {
        lock.withLock {
            frame = rect
            self.window = window
        }
    }

    func clear() {
        lock.withLock {
            frame = nil
            window = nil
        }
    }

    func setPort(_ port: CFMachPort?) {
        lock.withLock { portValue = port }
    }
}
