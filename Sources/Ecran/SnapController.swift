import AppKit
import ApplicationServices
import Domain
import Infrastructure
import WindowGeometry

@MainActor
final class SnapController {
    private let runtime: EcranRuntime
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var footprint: NSWindow?
    private var currentHit: SnapHit?
    private var draggedElement: AXUIElement?
    private var originalFrame: CGRect?
    private var windowMoving = false
    private var dragStartedAt: Date?
    private let gate = SnapGate()

    init(runtime: EcranRuntime) {
        self.runtime = runtime
        refreshGate()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: .settingsDidChange,
            object: nil
        )
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] event in
            guard self?.gate.enabled == true else { return }
            Task { @MainActor in
                self?.handle(event)
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
        hideFootprint()
    }

    @objc private func settingsChanged() {
        refreshGate()
    }

    private func refreshGate() {
        gate.enabled = runtime.snapIsEnabled()
    }

    private func handle(_ event: NSEvent) {
        let enabled = runtime.snapIsEnabled()
        gate.enabled = enabled
        guard enabled, runtime.accessibilityTrusted else { return }
        if event.type == .leftMouseUp {
            if windowMoving, let hit = currentHit, let element = draggedElement {
                runtime.mover.apply(
                    clampOwnWindow(hit.rect, of: element),
                    settings: runtime.settings,
                    action: hit.action,
                    element: element
                )
                TodoController.reflow(settings: runtime.settings)
            }
            resetDrag()
            return
        }
        guard event.type == .leftMouseDragged else { return }
        if let window = event.window {
            let mask = window.styleMask
            guard mask.contains(.titled), mask.contains(.resizable) else { return }
        }
        let cursor = ScreenCatalog.cocoaToAccessibility(NSEvent.mouseLocation)
        if draggedElement == nil {
            guard let element = WindowCatalog.windowForDrag(at: cursor),
                  WindowCatalog.isSnappableWindow(element),
                  let frame = WindowCatalog.frame(of: element)
            else { return }
            draggedElement = element
            originalFrame = frame
            dragStartedAt = Date()
        }
        guard let element = draggedElement, let frame = WindowCatalog.frame(of: element) else { return }
        if !windowMoving {
            guard let original = originalFrame, SnapDrag.isWindowMove(from: original, to: frame) else { return }
            windowMoving = true
            let windowID = WindowCatalog.windowID(for: element)
            if runtime.settings.unsnapRestore, runtime.mover.windowHistory.matchesLastRectangle(windowID, frame: frame),
               let restored = runtime.mover.windowHistory.restoreRect(for: windowID)
            {
                WindowCatalog.setFrame(restored, of: element)
            }
        }
        let screen = ScreenCatalog.screen(containing: frame, settings: runtime.settings, cursor: cursor)
        if let hit = SnapDetection.hit(
            cursor: cursor,
            screen: screen,
            settings: runtime.settings,
            prior: currentHit,
            window: originalFrame ?? frame
        ) {
            if runtime.settings.missionControlDragging, hit.zone == .top,
               Date().timeIntervalSince(dragStartedAt ?? Date()) < 0.2
            {
                currentHit = nil
                hideFootprint()
                return
            }
            if currentHit?.zone != hit.zone || currentHit?.action != hit.action {
                currentHit = hit
                showFootprint(clampOwnWindow(hit.rect, of: element))
                if runtime.settings.hapticFeedbackOnSnap {
                    HapticFeedback.alignment()
                }
            }
        } else {
            currentHit = nil
            hideFootprint()
        }
    }

    private func clampOwnWindow(_ rect: CGRect, of element: AXUIElement) -> CGRect {
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        guard pid == ProcessInfo.processInfo.processIdentifier else { return rect }
        var clamped = rect
        let min = SettingsWindowMetrics.minSize
        if clamped.width < min.width { clamped.size.width = min.width }
        if clamped.height < min.height { clamped.size.height = min.height }
        return clamped
    }

    private func resetDrag() {
        currentHit = nil
        originalFrame = nil
        draggedElement = nil
        windowMoving = false
        dragStartedAt = nil
        hideFootprint()
    }

    private func showFootprint(_ rect: CGRect) {
        let cocoa = ScreenCatalog.accessibilityToCocoa(rect)
        if footprint == nil {
            let window = NSWindow(
                contentRect: cocoa,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = NSColor.white.withAlphaComponent(runtime.settings.footprintAlpha)
            window.level = .floating
            window.ignoresMouseEvents = true
            window.hasShadow = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            footprint = window
        }
        if runtime.settings.animateFootprint {
            footprint?.animator().setFrame(cocoa, display: true)
        } else {
            footprint?.setFrame(cocoa, display: true)
        }
        footprint?.orderFront(nil)
    }

    private func hideFootprint() {
        footprint?.orderOut(nil)
    }
}

private final class SnapGate: @unchecked Sendable {
    private let lock = NSLock()
    private var enabledValue = false

    var enabled: Bool {
        get { lock.withLock { enabledValue } }
        set { lock.withLock { enabledValue = newValue } }
    }
}
