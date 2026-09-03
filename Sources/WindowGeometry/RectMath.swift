import CoreGraphics
import Domain
import Foundation

public struct ScreenFrame: Hashable, Sendable {
    public var visible: CGRect
    public var full: CGRect
    public var isMain: Bool
    public var hasNotch: Bool
    public var index: Int

    public init(visible: CGRect, full: CGRect, isMain: Bool, hasNotch: Bool, index: Int) {
        self.visible = visible
        self.full = full
        self.isMain = isMain
        self.hasNotch = hasNotch
        self.index = index
    }

    public var isPortrait: Bool {
        visible.height > visible.width
    }
}

public struct LayoutRequest: Sendable {
    public var action: WindowAction
    public var window: CGRect
    public var screen: ScreenFrame
    public var screens: [ScreenFrame]
    public var lastAction: LastWindowAction?
    public var settings: AppSettings

    public init(
        action: WindowAction,
        window: CGRect,
        screen: ScreenFrame,
        screens: [ScreenFrame],
        lastAction: LastWindowAction? = nil,
        settings: AppSettings
    ) {
        self.action = action
        self.window = window
        self.screen = screen
        self.screens = screens
        self.lastAction = lastAction
        self.settings = settings
    }
}

public struct LayoutResult: Hashable, Sendable {
    public var rect: CGRect
    public var action: WindowAction
    public var subAction: String?
    public var screenIndex: Int

    public init(rect: CGRect, action: WindowAction, subAction: String? = nil, screenIndex: Int) {
        self.rect = rect
        self.action = action
        self.subAction = subAction
        self.screenIndex = screenIndex
    }
}

public enum RectMath {
    public static func floorDimension(_ value: CGFloat) -> CGFloat {
        floor(value + 0.0001)
    }

    public static func band(
        in frame: CGRect,
        index: Int,
        count: Int,
        horizontal: Bool
    ) -> CGRect {
        guard count > 0 else { return frame }
        let clamped = min(max(index, 0), count - 1)
        if horizontal {
            let width = floorDimension(frame.width / CGFloat(count))
            return CGRect(
                x: frame.minX + width * CGFloat(clamped),
                y: frame.minY,
                width: clamped == count - 1 ? frame.maxX - (frame.minX + width * CGFloat(clamped)) : width,
                height: frame.height
            )
        }
        // Accessibility space: minY is the top of the screen.
        let height = floorDimension(frame.height / CGFloat(count))
        let y = frame.minY + height * CGFloat(clamped)
        return CGRect(
            x: frame.minX,
            y: y,
            width: frame.width,
            height: clamped == count - 1 ? frame.maxY - y : height
        )
    }

    public static func span(
        in frame: CGRect,
        start: Int,
        length: Int,
        count: Int,
        horizontal: Bool
    ) -> CGRect {
        let first = band(in: frame, index: start, count: count, horizontal: horizontal)
        let last = band(in: frame, index: start + length - 1, count: count, horizontal: horizontal)
        return first.union(last)
    }

    public static func cell(
        in frame: CGRect,
        column: Int,
        row: Int,
        columns: Int,
        rows: Int
    ) -> CGRect {
        let horizontal = band(in: frame, index: column, count: columns, horizontal: true)
        let vertical = band(in: frame, index: row, count: rows, horizontal: false)
        return CGRect(
            x: horizontal.minX,
            y: vertical.minY,
            width: horizontal.width,
            height: vertical.height
        )
    }

    public static func leading(in frame: CGRect, fraction: Double, horizontal: Bool) -> CGRect {
        if horizontal {
            return CGRect(
                x: frame.minX,
                y: frame.minY,
                width: floorDimension(frame.width * fraction),
                height: frame.height
            )
        }
        let height = floorDimension(frame.height * fraction)
        return CGRect(
            x: frame.minX,
            y: frame.minY,
            width: frame.width,
            height: height
        )
    }

    public static func trailing(in frame: CGRect, fraction: Double, horizontal: Bool) -> CGRect {
        if horizontal {
            let width = floorDimension(frame.width * fraction)
            return CGRect(
                x: frame.maxX - width,
                y: frame.minY,
                width: width,
                height: frame.height
            )
        }
        let height = floorDimension(frame.height * fraction)
        return CGRect(
            x: frame.minX,
            y: frame.maxY - height,
            width: frame.width,
            height: height
        )
    }

    public static func centered(_ window: CGRect, in frame: CGRect) -> CGRect {
        CGRect(
            x: frame.midX - window.width / 2,
            y: frame.midY - window.height / 2,
            width: window.width,
            height: window.height
        )
    }

    public static func inset(_ rect: CGRect, edges: EdgeInsets) -> CGRect {
        CGRect(
            x: rect.minX + edges.left,
            y: rect.minY + edges.top,
            width: max(0, rect.width - edges.left - edges.right),
            height: max(0, rect.height - edges.top - edges.bottom)
        )
    }
}

public struct EdgeInsets: Hashable, Sendable {
    public var top: CGFloat
    public var bottom: CGFloat
    public var left: CGFloat
    public var right: CGFloat

    public init(top: CGFloat = 0, bottom: CGFloat = 0, left: CGFloat = 0, right: CGFloat = 0) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
    }
}

public enum GapPolicy {
    public static func usableFrame(
        for screen: ScreenFrame,
        settings: AppSettings,
        todoReserved: CGFloat = 0,
        reserveTodo: Bool = true
    ) -> CGRect {
        var insets = EdgeInsets(
            top: settings.screenEdgeGapTop,
            bottom: settings.screenEdgeGapBottom,
            left: settings.screenEdgeGapLeft,
            right: settings.screenEdgeGapRight
        )
        if settings.screenEdgeGapsOnMainScreenOnly, !screen.isMain {
            insets = EdgeInsets()
        }
        if screen.hasNotch {
            insets.top += settings.screenEdgeGapTopNotch
        }
        let reserved: CGFloat
        if !reserveTodo {
            reserved = 0
        } else if todoReserved > 0 {
            reserved = todoReserved
        } else if settings.todoMode {
            reserved = settings.todoIsFraction ? screen.visible.width * settings.todoWidth : settings.todoWidth
        } else {
            reserved = 0
        }
        if reserved > 0 {
            if settings.todoSide == .left {
                insets.left += reserved
            } else {
                insets.right += reserved
            }
        }
        return RectMath.inset(screen.visible, edges: insets)
    }

    public static func applyGaps(
        _ rect: CGRect,
        action: WindowAction,
        settings: AppSettings
    ) -> CGRect {
        let gap = settings.gapSize
        guard gap > 0 else { return rect }
        if action == .maximize, !settings.applyGapsToMaximize { return rect }
        if action == .maximizeHeight, !settings.applyGapsToMaximizeHeight { return rect }
        var inset = rect.insetBy(dx: gap, dy: gap)
        let shared = action.gapSharedEdges
        if shared.contains(.left) {
            inset.origin.x -= gap / 2
            inset.size.width += gap / 2
        }
        if shared.contains(.right) {
            inset.size.width += gap / 2
        }
        if shared.contains(.bottom) {
            inset.size.height += gap / 2
        }
        if shared.contains(.top) {
            inset.origin.y -= gap / 2
            inset.size.height += gap / 2
        }
        if settings.skipGapTopEdge, !shared.contains(.top) {
            inset.origin.y -= gap
            inset.size.height += gap
        }
        return inset
    }
}
