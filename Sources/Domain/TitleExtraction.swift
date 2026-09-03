import Foundation

public enum TitleExtractionStrategy: String, CaseIterable, Codable, Sendable {
    case firstPart
    case lastPart
    case beforeFirstSeparator
    case afterLastSeparator
    case fullTitle

    public var displayName: String {
        switch self {
        case .firstPart: "First part"
        case .lastPart: "Last part"
        case .beforeFirstSeparator: "Before first separator"
        case .afterLastSeparator: "After last separator"
        case .fullTitle: "Full title"
        }
    }
}

public struct AppTitleConfig: Hashable, Codable, Sendable {
    public var strategy: TitleExtractionStrategy
    public var customSeparator: String

    public init(
        strategy: TitleExtractionStrategy = .beforeFirstSeparator,
        customSeparator: String = " - "
    ) {
        self.strategy = strategy
        self.customSeparator = customSeparator
    }
}

public enum TitleExtractor {
    public static let commonSeparators = [" - ", " — ", " | ", " / ", " \\ "]
    public static let beforeAfterSeparators = [" — ", " - ", " | ", " / ", " \\ "]

    public static let builtInAppConfigs: [String: AppTitleConfig] = [
        "com.jetbrains.intellij": AppTitleConfig(strategy: .beforeFirstSeparator, customSeparator: " – "),
        "com.apple.dt.Xcode": AppTitleConfig(strategy: .beforeFirstSeparator, customSeparator: " — "),
        "com.microsoft.VSCode": AppTitleConfig(strategy: .afterLastSeparator, customSeparator: " - "),
        "com.todesktop.230313mzl4w4u92": AppTitleConfig(strategy: .afterLastSeparator, customSeparator: " - "),
        "com.apple.Safari": AppTitleConfig(strategy: .beforeFirstSeparator, customSeparator: " — "),
    ]

    public static func extract(
        _ title: String,
        using strategy: TitleExtractionStrategy,
        customSeparator: String?
    ) -> String {
        guard !title.isEmpty else { return title }
        switch strategy {
        case .firstPart:
            return firstPart(of: title, customSeparator: customSeparator, separators: commonSeparators)
        case .lastPart:
            return lastPart(of: title, customSeparator: customSeparator, separators: commonSeparators)
        case .beforeFirstSeparator:
            return firstPart(of: title, customSeparator: customSeparator, separators: beforeAfterSeparators)
        case .afterLastSeparator:
            return lastPart(of: title, customSeparator: customSeparator, separators: beforeAfterSeparators)
        case .fullTitle:
            return title
        }
    }

    public static func extract(
        _ title: String,
        bundleID: String,
        appConfigs: [String: AppTitleConfig],
        defaultStrategy: TitleExtractionStrategy,
        defaultSeparator: String
    ) -> String {
        if let config = appConfigs[bundleID] {
            return extract(title, using: config.strategy, customSeparator: config.customSeparator)
        }
        return extract(title, using: defaultStrategy, customSeparator: defaultSeparator)
    }

    private static func firstPart(
        of title: String,
        customSeparator: String?,
        separators: [String]
    ) -> String {
        if let customSeparator, !customSeparator.isEmpty, let range = title.range(of: customSeparator) {
            return String(title[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        for separator in separators {
            if let range = title.range(of: separator) {
                return String(title[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            }
        }
        return title
    }

    private static func lastPart(
        of title: String,
        customSeparator: String?,
        separators: [String]
    ) -> String {
        if let customSeparator, !customSeparator.isEmpty,
           let range = title.range(of: customSeparator, options: .backwards)
        {
            return String(title[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        for separator in separators {
            if let range = title.range(of: separator, options: .backwards) {
                return String(title[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            }
        }
        return title
    }
}
