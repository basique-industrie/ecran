import Foundation

public enum SubsequentExecutionMode: String, CaseIterable, Codable, Sendable {
    case resize
    case acrossMonitor
    case none
    case acrossAndResize
    case cycleMonitor
    case resizeAndCycleQuadrants

    public var displayName: String {
        switch self {
        case .resize: "Cycle sizes"
        case .acrossMonitor: "Move across displays"
        case .none: "Do not repeat"
        case .acrossAndResize: "Displays, then sizes"
        case .cycleMonitor: "Any action to next display"
        case .resizeAndCycleQuadrants: "Cycle sizes and quarters"
        }
    }
}

public enum CycleSize: String, CaseIterable, Codable, Sendable {
    case half
    case twoThirds
    case threeFourths
    case oneFourth
    case oneThird

    public var fraction: Double {
        switch self {
        case .half: 0.5
        case .twoThirds: 2.0 / 3.0
        case .threeFourths: 0.75
        case .oneFourth: 0.25
        case .oneThird: 1.0 / 3.0
        }
    }

    public var displayName: String {
        switch self {
        case .half: "½"
        case .twoThirds: "⅔"
        case .threeFourths: "¾"
        case .oneFourth: "¼"
        case .oneThird: "⅓"
        }
    }

    public static let defaultSelection: [CycleSize] = [.half, .twoThirds, .oneThird]

    public static func sorted(_ selected: [CycleSize]) -> [CycleSize] {
        let order: [CycleSize] = [.half, .twoThirds, .threeFourths, .oneFourth, .oneThird]
        return order.filter { selected.contains($0) }
    }

    public static func next(after count: Int, selected: [CycleSize]) -> CycleSize {
        let sizes = sorted(selected)
        guard !sizes.isEmpty else { return .half }
        if sizes.contains(.half) {
            return sizes[count % sizes.count]
        }
        return sizes[max(0, count - 1) % sizes.count]
    }
}

public enum CornerCycleAxis: String, CaseIterable, Codable, Sendable {
    case horizontal
    case vertical

    public var displayName: String {
        switch self {
        case .horizontal: "Horizontal"
        case .vertical: "Vertical"
        }
    }
}

public enum ScreenOrder: String, CaseIterable, Codable, Sendable {
    case yThenMinX
    case minX
    case midX

    public var displayName: String {
        switch self {
        case .yThenMinX: "Rows, then left to right"
        case .minX: "Left to right"
        case .midX: "Center X"
        }
    }
}

public struct LastWindowAction: Hashable, Codable, Sendable {
    public var action: WindowAction
    public var subAction: String?
    public var rect: RectSnapshot
    public var count: Int

    public init(action: WindowAction, subAction: String? = nil, rect: RectSnapshot, count: Int = 1) {
        self.action = action
        self.subAction = subAction
        self.rect = rect
        self.count = count
    }
}

public struct RectSnapshot: Hashable, Codable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public static let zero = RectSnapshot(x: 0, y: 0, width: 0, height: 0)
}
