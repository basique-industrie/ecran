import CoreGraphics
import Domain
import Foundation

public struct SnapHit: Hashable, Sendable {
    public var zone: SnapZone
    public var action: WindowAction
    public var rect: CGRect

    public init(zone: SnapZone, action: WindowAction, rect: CGRect) {
        self.zone = zone
        self.action = action
        self.rect = rect
    }
}

public enum SnapDrag {
    public static let moveThreshold: CGFloat = 2

    public static func isWindowMove(from original: CGRect, to current: CGRect, threshold: CGFloat = moveThreshold) -> Bool {
        abs(original.origin.x - current.origin.x) > threshold
            || abs(original.origin.y - current.origin.y) > threshold
    }
}

public enum SnapDetection {
    public static func hit(
        cursor: CGPoint,
        screen: ScreenFrame,
        settings: AppSettings,
        prior: SnapHit? = nil,
        window: CGRect? = nil
    ) -> SnapHit? {
        guard settings.windowSnapping else { return nil }
        let frame = screen.full
        let margins = settings.snapMargins
        let portrait = screen.isPortrait
        let nearLeft = cursor.x <= frame.minX + margins.edge
        let nearRight = cursor.x >= frame.maxX - margins.edge
        let nearTop = cursor.y <= frame.minY + margins.edge
        let nearBottom = cursor.y >= frame.maxY - margins.edge
        guard nearLeft || nearRight || nearTop || nearBottom else { return nil }

        let zone: SnapZone
        if nearTop, cursor.x <= frame.minX + margins.corner {
            zone = .topLeft
        } else if nearTop, cursor.x >= frame.maxX - margins.corner {
            zone = .topRight
        } else if nearBottom, cursor.x <= frame.minX + margins.corner {
            zone = .bottomLeft
        } else if nearBottom, cursor.x >= frame.maxX - margins.corner {
            zone = .bottomRight
        } else if nearLeft, cursor.y <= frame.minY + margins.shortEdge {
            zone = .leftTop
        } else if nearLeft, cursor.y >= frame.maxY - margins.shortEdge {
            zone = .leftBottom
        } else if nearRight, cursor.y <= frame.minY + margins.shortEdge {
            zone = .rightTop
        } else if nearRight, cursor.y >= frame.maxY - margins.shortEdge {
            zone = .rightBottom
        } else if nearBottom {
            let third = frame.width / 3
            if cursor.x < frame.minX + third {
                zone = .bottomLeftThird
            } else if cursor.x > frame.maxX - third {
                zone = .bottomRightThird
            } else {
                zone = .bottomCenterThird
            }
        } else if nearTop {
            zone = .top
        } else if nearLeft {
            zone = .left
        } else {
            zone = .right
        }

        var action = settings.snapAreas.action(for: zone, portrait: portrait)
        if settings.sixthsSnapArea {
            action = sixthsAction(for: zone) ?? action
        }
        action = compoundAction(for: zone, prior: prior, fallback: action)
        let layout = WindowLayoutEngine.calculate(
            LayoutRequest(
                action: action,
                window: window ?? frame,
                screen: screen,
                screens: [screen],
                settings: settings
            )
        )
        return SnapHit(zone: zone, action: action, rect: layout.rect)
    }

    private static func sixthsAction(for zone: SnapZone) -> WindowAction? {
        switch zone {
        case .topLeft: .topLeftSixth
        case .topRight: .topRightSixth
        case .bottomLeft: .bottomLeftSixth
        case .bottomRight: .bottomRightSixth
        case .leftTop: .topLeftSixth
        case .rightTop: .topRightSixth
        case .leftBottom: .bottomLeftSixth
        case .rightBottom: .bottomRightSixth
        default: nil
        }
    }

    private static func compoundAction(for zone: SnapZone, prior: SnapHit?, fallback: WindowAction) -> WindowAction {
        guard zone == .bottomCenterThird, let prior else { return fallback }
        switch prior.action {
        case .firstThird, .firstTwoThirds:
            return .firstTwoThirds
        case .lastThird, .lastTwoThirds:
            return .lastTwoThirds
        default:
            return fallback
        }
    }
}
