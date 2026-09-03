import Foundation

public struct SwitcherPalette: Hashable, Sendable {
    public var primaryRed: Double
    public var primaryGreen: Double
    public var primaryBlue: Double
    public var secondaryRed: Double
    public var secondaryGreen: Double
    public var secondaryBlue: Double
    public var usesSystemAccent: Bool

    public init(
        primaryRed: Double,
        primaryGreen: Double,
        primaryBlue: Double,
        secondaryRed: Double,
        secondaryGreen: Double,
        secondaryBlue: Double,
        usesSystemAccent: Bool = false
    ) {
        self.primaryRed = primaryRed
        self.primaryGreen = primaryGreen
        self.primaryBlue = primaryBlue
        self.secondaryRed = secondaryRed
        self.secondaryGreen = secondaryGreen
        self.secondaryBlue = secondaryBlue
        self.usesSystemAccent = usesSystemAccent
    }
}

public extension SwitcherColorScheme {
    var palette: SwitcherPalette {
        switch self {
        case .system:
            SwitcherPalette(
                primaryRed: 0.4,
                primaryGreen: 0.6,
                primaryBlue: 1,
                secondaryRed: 0.4,
                secondaryGreen: 0.6,
                secondaryBlue: 1,
                usesSystemAccent: true
            )
        case .cyberpunk:
            SwitcherPalette(primaryRed: 0, primaryGreen: 1, primaryBlue: 0.8, secondaryRed: 1, secondaryGreen: 0, secondaryBlue: 0.8)
        case .sunset:
            SwitcherPalette(primaryRed: 1, primaryGreen: 0.4, primaryBlue: 0.2, secondaryRed: 1, secondaryGreen: 0.8, secondaryBlue: 0)
        case .forest:
            SwitcherPalette(primaryRed: 0.2, primaryGreen: 0.8, primaryBlue: 0.4, secondaryRed: 0, secondaryGreen: 0.6, secondaryBlue: 0.3)
        case .ocean:
            SwitcherPalette(primaryRed: 0.2, primaryGreen: 0.6, primaryBlue: 1, secondaryRed: 0, secondaryGreen: 0.8, secondaryBlue: 0.8)
        case .rose:
            SwitcherPalette(primaryRed: 1, primaryGreen: 0.2, primaryBlue: 0.6, secondaryRed: 0.8, secondaryGreen: 0, secondaryBlue: 0.4)
        case .graphite:
            SwitcherPalette(primaryRed: 0.4, primaryGreen: 0.4, primaryBlue: 0.5, secondaryRed: 0.6, secondaryGreen: 0.6, secondaryBlue: 0.7)
        case .indigo:
            SwitcherPalette(primaryRed: 0.4, primaryGreen: 0.2, primaryBlue: 0.8, secondaryRed: 0.2, secondaryGreen: 0, secondaryBlue: 0.6)
        case .aurora:
            SwitcherPalette(primaryRed: 0, primaryGreen: 0.8, primaryBlue: 0.6, secondaryRed: 0, secondaryGreen: 0.4, secondaryBlue: 0.8)
        case .midnight:
            SwitcherPalette(primaryRed: 0.6, primaryGreen: 0.2, primaryBlue: 0.8, secondaryRed: 0.4, secondaryGreen: 0, secondaryBlue: 0.6)
        }
    }
}
