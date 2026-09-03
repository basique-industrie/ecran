import AppKit
import Domain
import Foundation
import WindowGeometry

public enum ScreenCatalog {
    public static func all() -> [ScreenFrame] {
        NSScreen.screens.enumerated().map { index, screen in
            ScreenFrame(
                visible: cocoaToAccessibility(screen.visibleFrame),
                full: cocoaToAccessibility(screen.frame),
                isMain: screen == NSScreen.main,
                hasNotch: screen.safeAreaInsets.top > 0,
                index: index
            )
        }
    }

    public static func effective(settings: AppSettings) -> [ScreenFrame] {
        let screens = all()
        guard settings.combinedDisplayMode, screens.count > 1 else { return screens }
        let visible = screens.reduce(CGRect.null) { $0.union($1.visible) }
        let full = screens.reduce(CGRect.null) { $0.union($1.full) }
        return [
            ScreenFrame(
                visible: visible,
                full: full,
                isMain: true,
                hasNotch: screens.contains(where: \.hasNotch),
                index: 0
            ),
        ]
    }

    public static func primaryScreen() -> NSScreen? {
        NSScreen.screens.first { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return false
            }
            return CGDisplayIsMain(CGDirectDisplayID(number.uint32Value)) != 0
        } ?? NSScreen.screens.first
    }

    public static func screenContainingActiveWindow() -> NSScreen? {
        guard let element = WindowCatalog.focusedWindowElement(),
              let frame = WindowCatalog.frame(of: element)
        else {
            return NSScreen.main
        }
        let cocoa = accessibilityToCocoa(frame)
        let point = CGPoint(x: cocoa.midX, y: cocoa.midY)
        return NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main
    }

    public static func screen(containing rect: CGRect, settings: AppSettings, cursor: CGPoint?) -> ScreenFrame {
        let screens = effective(settings: settings)
        if settings.useCursorScreenDetection, let cursor, let match = screens.first(where: { $0.full.contains(cursor) }) {
            return match
        }
        return screens.max { lhs, rhs in
            lhs.visible.intersection(rect).area < rhs.visible.intersection(rect).area
        } ?? screens.first ?? ScreenFrame(visible: .zero, full: .zero, isMain: true, hasNotch: false, index: 0)
    }

    public static func cocoaToAccessibility(_ rect: CGRect) -> CGRect {
        guard let primary = NSScreen.screens.first else { return rect }
        return CGRect(
            x: rect.minX,
            y: primary.frame.maxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    public static func cocoaToAccessibility(_ point: CGPoint) -> CGPoint {
        guard let primary = NSScreen.screens.first else { return point }
        return CGPoint(x: point.x, y: primary.frame.maxY - point.y)
    }

    public static func accessibilityToCocoa(_ rect: CGRect) -> CGRect {
        cocoaToAccessibility(rect)
    }
}

private extension CGRect {
    var area: CGFloat { max(0, width) * max(0, height) }
}
