import Foundation

public enum SpaceMembership {
    /// Fullscreen windows live on type-4 Spaces that have no desktop number.
    /// Membership has to compare Space IDs, not the 1-based desktop index.
    public static func isOnOtherSpace(
        windowSpaces: [UInt64],
        currentSpaces: [UInt64],
        isMinimized: Bool
    ) -> Bool {
        guard !isMinimized, !windowSpaces.isEmpty else { return false }
        return !windowSpaces.contains { currentSpaces.contains($0) }
    }
}
