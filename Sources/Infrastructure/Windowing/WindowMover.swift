import AppKit
import ApplicationServices
import Domain
import Foundation
import WindowGeometry

@MainActor
public final class WindowMover {
    private let history = WindowHistory()

    public init() {}

    public var windowHistory: WindowHistory { history }

    @discardableResult
    public func execute(_ action: WindowAction, settings: AppSettings, element: AXUIElement? = nil) -> Bool {
        if action.isMultiWindow {
            return executeMultiWindow(action, settings: settings)
        }
        guard let element = element ?? WindowCatalog.focusedWindowElement(),
              let original = WindowCatalog.frame(of: element)
        else {
            return false
        }
        if action == .restore {
            let windowID = SkyLight.windowID(for: element)
            if let restored = history.restore(windowID: windowID) {
                WindowCatalog.setFrame(restored, of: element)
                return true
            }
            return false
        }
        let cursor = ScreenCatalog.cocoaToAccessibility(NSEvent.mouseLocation)
        let screen = ScreenCatalog.screen(containing: original, settings: settings, cursor: cursor)
        let screens = ScreenCatalog.effective(settings: settings)
        let windowID = SkyLight.windowID(for: element)
        let last = history.lastAction(for: windowID)
        let result = WindowLayoutEngine.calculate(
            LayoutRequest(
                action: action,
                window: original,
                screen: screen,
                screens: screens,
                lastAction: last,
                settings: settings
            )
        )
        WindowCatalog.setFrame(result.rect, of: element, adjustSizeFirst: shouldAdjustSizeFirst(result.action, settings: settings))
        let applied = WindowCatalog.frame(of: element) ?? result.rect
        history.record(windowID: windowID, original: original, result: applied, action: result.action, subAction: result.subAction)
        applyCooperativeCorner(placed: applied, placedID: windowID, action: result.action, screen: screen, settings: settings)
        if settings.moveCursorWithActions || (settings.moveCursorAcrossDisplays && result.screenIndex != screen.index) {
            CGWarpMouseCursorPosition(CGPoint(x: applied.midX, y: applied.midY))
        }
        AppLog.windows.info("Applied \(action.kebabName)")
        return true
    }

    public func executeCycle(_ actions: [WindowAction], settings: AppSettings) -> Bool {
        guard let element = WindowCatalog.focusedWindowElement(),
              let frame = WindowCatalog.frame(of: element)
        else {
            return false
        }
        let windowID = SkyLight.windowID(for: element)
        let last = history.lastAction(for: windowID)
        let stale = last == nil || !history.matchesLastRectangle(windowID, frame: frame)
        let next = ShortcutCycle.next(after: stale ? nil : last?.action, in: actions)
        return execute(next, settings: settings, element: element)
    }

    public func apply(_ rect: CGRect, settings: AppSettings, action: WindowAction, element: AXUIElement? = nil) {
        guard let element = element ?? WindowCatalog.focusedWindowElement(),
              let original = WindowCatalog.frame(of: element)
        else { return }
        WindowCatalog.setFrame(rect, of: element, adjustSizeFirst: shouldAdjustSizeFirst(action, settings: settings))
        let applied = WindowCatalog.frame(of: element) ?? rect
        let windowID = SkyLight.windowID(for: element)
        history.record(
            windowID: windowID,
            original: original,
            result: applied,
            action: action,
            subAction: nil
        )
        let cursor = ScreenCatalog.cocoaToAccessibility(NSEvent.mouseLocation)
        let screen = ScreenCatalog.screen(containing: applied, settings: settings, cursor: cursor)
        applyCooperativeCorner(placed: applied, placedID: windowID, action: action, screen: screen, settings: settings)
    }

    private func applyCooperativeCorner(
        placed: CGRect,
        placedID: CGWindowID,
        action: WindowAction,
        screen: ScreenFrame,
        settings: AppSettings
    ) {
        guard settings.cooperativeCornerResize else { return }
        let usable = GapPolicy.usableFrame(for: screen, settings: settings)
        guard let band = CooperativeCorner.complementaryBand(action: action, placed: placed, usable: usable) else {
            return
        }
        let neighbors = WindowCatalog.onScreenWindows(
            settings: settings,
            excludingBundleID: Bundle.main.bundleIdentifier
        )
        for item in neighbors {
            guard item.record.windowID != placedID,
                  CooperativeCorner.shouldResize(item.frame, into: band, excluding: placed)
            else { continue }
            WindowCatalog.setFrame(band, of: item.element)
            let applied = WindowCatalog.frame(of: item.element) ?? band
            history.record(
                windowID: item.record.windowID,
                original: item.frame,
                result: applied,
                action: action,
                subAction: "cooperative"
            )
            return
        }
    }

    private func shouldAdjustSizeFirst(_ action: WindowAction, settings: AppSettings) -> Bool {
        switch (action, settings.cornerCycleAxis) {
        case (.topRight, .horizontal), (.bottomRight, .horizontal), (.bottomLeft, .vertical), (.bottomRight, .vertical):
            false
        default:
            true
        }
    }

    private func executeMultiWindow(_ action: WindowAction, settings: AppSettings) -> Bool {
        guard let app = NSWorkspace.shared.frontmostApplication else { return false }
        let screen = ScreenCatalog.screen(
            containing: NSScreen.main.map { ScreenCatalog.cocoaToAccessibility($0.visibleFrame) } ?? .zero,
            settings: settings,
            cursor: nil
        )
        let frame = GapPolicy.usableFrame(for: screen, settings: settings)
        let located = WindowCatalog.onScreenWindows(
            settings: settings,
            excludingBundleID: Bundle.main.bundleIdentifier,
            processID: action == .tileActiveApp || action == .cascadeActiveApp ? app.processIdentifier : nil
        )
        let elements = located.map { ($0.record, $0.element, $0.frame) }
        let frames = elements.map(\.2)
        let next: [CGRect]
        switch action {
        case .tileAll, .tileActiveApp:
            next = WindowLayoutEngine.tile(frames, in: frame, settings: settings)
        case .cascadeAll, .cascadeActiveApp:
            next = WindowLayoutEngine.cascade(frames, in: frame, settings: settings)
        case .reverseAll:
            next = WindowLayoutEngine.reverse(frames, in: frame)
        default:
            return false
        }
        for (index, item) in elements.enumerated() where index < next.count {
            WindowCatalog.setFrame(next[index], of: item.1)
        }
        return true
    }
}
