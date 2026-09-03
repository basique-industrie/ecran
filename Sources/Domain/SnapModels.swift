import Foundation

public enum SnapZone: String, CaseIterable, Codable, Sendable {
    case left
    case right
    case top
    case bottom
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case leftTop
    case leftBottom
    case rightTop
    case rightBottom
    case bottomLeftThird
    case bottomCenterThird
    case bottomRightThird

    public var defaultAction: WindowAction {
        switch self {
        case .left: .leftHalf
        case .right: .rightHalf
        case .top: .maximize
        case .bottom: .bottomHalf
        case .topLeft: .topLeft
        case .topRight: .topRight
        case .bottomLeft: .bottomLeft
        case .bottomRight: .bottomRight
        case .leftTop: .topHalf
        case .leftBottom: .bottomHalf
        case .rightTop: .topHalf
        case .rightBottom: .bottomHalf
        case .bottomLeftThird: .firstThird
        case .bottomCenterThird: .centerThird
        case .bottomRightThird: .lastThird
        }
    }
}

public struct SnapAreaMap: Hashable, Codable, Sendable {
    public var landscape: [SnapZone: WindowAction]
    public var portrait: [SnapZone: WindowAction]

    public init(
        landscape: [SnapZone: WindowAction] = SnapAreaMap.defaultLandscape,
        portrait: [SnapZone: WindowAction] = SnapAreaMap.defaultPortrait
    ) {
        self.landscape = landscape
        self.portrait = portrait
    }

    public static let defaultLandscape: [SnapZone: WindowAction] = [
        .left: .leftHalf,
        .right: .rightHalf,
        .top: .maximize,
        .bottom: .centerThird,
        .topLeft: .topLeft,
        .topRight: .topRight,
        .bottomLeft: .bottomLeft,
        .bottomRight: .bottomRight,
        .leftTop: .topHalf,
        .leftBottom: .bottomHalf,
        .rightTop: .topHalf,
        .rightBottom: .bottomHalf,
        .bottomLeftThird: .firstThird,
        .bottomCenterThird: .centerThird,
        .bottomRightThird: .lastThird,
    ]

    public static let defaultPortrait: [SnapZone: WindowAction] = [
        .left: .firstThird,
        .right: .lastThird,
        .top: .maximize,
        .bottom: .bottomHalf,
        .topLeft: .topLeft,
        .topRight: .topRight,
        .bottomLeft: .bottomLeft,
        .bottomRight: .bottomRight,
        .leftTop: .firstTwoThirds,
        .leftBottom: .lastTwoThirds,
        .rightTop: .firstTwoThirds,
        .rightBottom: .lastTwoThirds,
        .bottomLeftThird: .leftHalf,
        .bottomCenterThird: .centerHalf,
        .bottomRightThird: .rightHalf,
    ]

    public func action(for zone: SnapZone, portrait: Bool) -> WindowAction {
        (portrait ? self.portrait : landscape)[zone] ?? zone.defaultAction
    }
}

public struct SnapMargins: Hashable, Codable, Sendable {
    public var edge: Double
    public var corner: Double
    public var shortEdge: Double

    public init(edge: Double = 5, corner: Double = 20, shortEdge: Double = 145) {
        self.edge = edge
        self.corner = corner
        self.shortEdge = shortEdge
    }
}
