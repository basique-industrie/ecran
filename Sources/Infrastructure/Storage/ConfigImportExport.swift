import Domain
import Foundation

public struct ExportedConfig: Codable, Sendable {
    public var bundleId: String
    public var version: String
    public var schema: String
    public var settings: AppSettings
    public var titleConfigs: [String: AppTitleConfig]

    public init(
        bundleId: String = AppIdentity.current.bundleIdentifier,
        version: String,
        settings: AppSettings
    ) {
        self.bundleId = bundleId
        self.version = version
        self.schema = "1.0"
        self.settings = settings
        self.titleConfigs = settings.appTitleConfigs
    }
}

public struct TitleConfigDocument: Codable, Sendable {
    public var schemaVersion: String?
    public var appTitleConfigs: [String: AppTitleConfig]

    public init(schemaVersion: String? = "1.0", appTitleConfigs: [String: AppTitleConfig]) {
        self.schemaVersion = schemaVersion
        self.appTitleConfigs = appTitleConfigs
    }
}

public enum ConfigImportExport {
    public static func export(_ settings: AppSettings, version: String) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(ExportedConfig(version: version, settings: settings))
    }

    public static func exportTitles(_ settings: AppSettings) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(TitleConfigDocument(appTitleConfigs: settings.appTitleConfigs))
    }

    public static func importSettings(from data: Data, into current: AppSettings, titlesOnly: Bool) throws -> AppSettings {
        let decoder = JSONDecoder()
        if let exported = try? decoder.decode(ExportedConfig.self, from: data) {
            if titlesOnly {
                var merged = current
                merged.appTitleConfigs.merge(exported.titleConfigs) { _, new in new }
                return merged
            }
            return exported.settings
        }
        if let titles = try? decoder.decode(TitleConfigDocument.self, from: data) {
            var merged = current
            merged.appTitleConfigs.merge(titles.appTitleConfigs) { _, new in new }
            return merged
        }
        throw CocoaError(.fileReadCorruptFile)
    }
}
