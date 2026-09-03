import Foundation

public enum ActionSource: String, Sendable {
    case hotkey
    case menu
    case url
    case snap
    case titleBar
    case greenButton
}

public enum FeatureIsolation {
    public static func placementHotkeysEnabled(switcherOpen: Bool, frontmostIgnored: Bool) -> Bool {
        !switcherOpen && !frontmostIgnored
    }

    public static func snapEnabled(
        windowSnapping: Bool,
        ignoreDragSnapToo: Bool,
        switcherOpen: Bool,
        frontmostIgnored: Bool
    ) -> Bool {
        guard windowSnapping, !switcherOpen else { return false }
        if frontmostIgnored, ignoreDragSnapToo { return false }
        return true
    }

    public static func switcherHotkeysEnabled(frontmostIgnored: Bool) -> Bool {
        // Ignore list is a placement/snap gate. The switcher stays available.
        _ = frontmostIgnored
        return true
    }
}

public enum TitleBarRestore {
    public static func shouldRestore(
        enabled: Bool,
        action: WindowAction,
        historyMatches: Bool,
        lastAction: WindowAction?
    ) -> Bool {
        guard enabled else { return false }
        return historyMatches && lastAction == action
    }
}
