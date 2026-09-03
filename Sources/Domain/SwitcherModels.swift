import Foundation

public enum WindowDisplayStyle: String, CaseIterable, Codable, Sendable {
    case appIcon
    case initials
    case preview

    public var displayName: String {
        switch self {
        case .appIcon: "App icon"
        case .initials: "Initials"
        case .preview: "Live preview"
        }
    }
}

public enum SwitcherHeaderStyle: String, CaseIterable, Codable, Sendable {
    case `default`
    case simplified

    public var displayName: String {
        switch self {
        case .default: "Title"
        case .simplified: "Simplified"
        }
    }
}

public enum SwitcherColorScheme: String, CaseIterable, Codable, Sendable {
    case system
    case cyberpunk
    case sunset
    case forest
    case ocean
    case rose
    case graphite
    case indigo
    case aurora
    case midnight

    public var displayName: String {
        switch self {
        case .system: "System"
        case .cyberpunk: "Cyberpunk"
        case .sunset: "Sunset"
        case .forest: "Forest"
        case .ocean: "Ocean"
        case .rose: "Rose"
        case .graphite: "Graphite"
        case .indigo: "Indigo"
        case .aurora: "Aurora"
        case .midnight: "Midnight"
        }
    }
}

public enum SwitcherKind: String, Sendable {
    case sameApp
    case apps
}

public enum SwitcherHold {
    public static func shouldDismissOnShow(modifierDown: Bool, held: Bool) -> Bool {
        !modifierDown && !held
    }
}

/// Which processes belong in the Command-Tab-style app list.
public enum AppSwitcherListing {
    public static func includes(
        isRegular: Bool,
        bundleID: String?,
        excludingBundleID: String?
    ) -> Bool {
        guard isRegular, let bundleID, !bundleID.isEmpty else { return false }
        return bundleID != excludingBundleID
    }

    /// When several processes share a bundle ID, keep the active one, else the frontmost.
    public static func prefersIncoming(
        existingActive: Bool,
        existingZOrder: Int,
        incomingActive: Bool,
        incomingZOrder: Int
    ) -> Bool {
        if incomingActive != existingActive {
            return incomingActive
        }
        return incomingZOrder < existingZOrder
    }
}

public struct WindowRecord: Hashable, Sendable {
    public var windowID: UInt32
    public var title: String
    public var projectName: String
    public var appName: String
    public var bundleID: String
    public var processID: Int32
    public var isMinimized: Bool
    public var isOnOtherSpace: Bool
    public var spaceIndex: Int
    public var layer: Int

    public init(
        windowID: UInt32,
        title: String,
        projectName: String,
        appName: String,
        bundleID: String,
        processID: Int32,
        isMinimized: Bool = false,
        isOnOtherSpace: Bool = false,
        spaceIndex: Int = 0,
        layer: Int = 0
    ) {
        self.windowID = windowID
        self.title = title
        self.projectName = projectName
        self.appName = appName
        self.bundleID = bundleID
        self.processID = processID
        self.isMinimized = isMinimized
        self.isOnOtherSpace = isOnOtherSpace
        self.spaceIndex = spaceIndex
        self.layer = layer
    }
}

public enum SwitcherPresentation {
    public static func windowCountLabel(_ count: Int) -> String {
        switch count {
        case 0: "No windows"
        case 1: "1 window"
        default: "\(count) windows"
        }
    }

    public static func spaceLabel(isOnOtherSpace: Bool, spaceIndex: Int) -> String? {
        guard isOnOtherSpace else { return nil }
        return spaceIndex > 0 ? "Desktop \(spaceIndex)" : "Other desktop"
    }
}

public struct AppRecord: Hashable, Sendable {
    public var bundleID: String
    public var processID: Int32
    public var appName: String
    public var windowCount: Int
    public var isActive: Bool

    public init(
        bundleID: String,
        processID: Int32,
        appName: String,
        windowCount: Int,
        isActive: Bool
    ) {
        self.bundleID = bundleID
        self.processID = processID
        self.appName = appName
        self.windowCount = windowCount
        self.isActive = isActive
    }
}
