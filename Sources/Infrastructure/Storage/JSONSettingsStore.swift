import Domain
import Foundation

public final class JSONSettingsStore: @unchecked Sendable {
    public static let currentSchemaVersion = 1

    public enum StoreError: LocalizedError {
        case invalidRoot
        case unsupportedSchema(Int)

        public var errorDescription: String? {
            switch self {
            case .invalidRoot: "Settings are not a valid JSON object"
            case .unsupportedSchema(let version):
                "Settings schema \(version) is newer than this app supports"
            }
        }
    }

    public let fileURL: URL
    private let lock = NSLock()
    private var cached: AppSettings?
    private var storedErrorDescription: String?

    public var lastErrorDescription: String? {
        lock.withLock { storedErrorDescription }
    }

    public var backupURL: URL {
        fileURL.appendingPathExtension("backup")
    }

    public init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? AppIdentity.current.settingsFileURL
    }

    public func load() -> AppSettings {
        lock.withLock {
            if let cached { return cached }
            let loaded = readUnsafe()
            cached = loaded
            return loaded
        }
    }

    public func save(_ settings: AppSettings) {
        do {
            try saveThrowing(settings)
        } catch {
            let message = error.localizedDescription
            lock.withLock { storedErrorDescription = message }
            AppLog.settings.error("Settings write failed: \(message)")
            NotificationCenter.default.post(
                name: .settingsStoreError,
                object: nil,
                userInfo: ["message": lastErrorDescription ?? message]
            )
        }
    }

    public func saveThrowing(_ settings: AppSettings) throws {
        try lock.withLock {
            var payload = try encode(settings)
            payload["_schemaVersion"] = Self.currentSchemaVersion
            try writeFile(payload, createBackup: true)
            cached = settings
            storedErrorDescription = nil
        }
    }

    private func readUnsafe() -> AppSettings {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .default
        }
        do {
            let data = try SettingsFilePolicy.readJSON(at: fileURL)
            var document = try decodeDocument(data)
            let version = document["_schemaVersion"] as? Int ?? 0
            guard version <= Self.currentSchemaVersion else {
                throw StoreError.unsupportedSchema(version)
            }
            if version < Self.currentSchemaVersion {
                document["_schemaVersion"] = Self.currentSchemaVersion
                try preserve(data, at: backupURL)
                try writeFile(document, createBackup: false)
            } else {
                enforcePermissions()
            }
            let settings = try decodeSettings(document)
            storedErrorDescription = nil
            return settings
        } catch {
            storedErrorDescription = error.localizedDescription
            AppLog.settings.error("Settings recovery required: \(error.localizedDescription)")
            return recoverInvalidSettings()
        }
    }

    private func decodeDocument(_ data: Data) throws -> [String: Any] {
        guard let document = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw StoreError.invalidRoot
        }
        return document
    }

    private func decodeSettings(_ document: [String: Any]) throws -> AppSettings {
        let data = try JSONSerialization.data(withJSONObject: document)
        return try JSONDecoder().decode(AppSettings.self, from: data)
    }

    private func encode(_ settings: AppSettings) throws -> [String: Any] {
        let data = try JSONEncoder().encode(settings)
        guard let document = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw StoreError.invalidRoot
        }
        return document
    }

    private func recoverInvalidSettings() -> AppSettings {
        preserveCorruptFile()
        if let backupData = try? Data(contentsOf: backupURL),
           let backup = try? decodeDocument(backupData),
           let settings = try? decodeSettings(backup)
        {
            try? writeFile(backup, createBackup: false)
            return settings
        }
        return .default
    }

    private func preserveCorruptFile() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let recoveryURL = fileURL.deletingPathExtension()
            .appendingPathExtension("corrupt-\(timestamp).json")
        try? FileManager.default.moveItem(at: fileURL, to: recoveryURL)
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: recoveryURL.path
        )
    }

    private func writeFile(_ dict: [String: Any], createBackup: Bool) throws {
        let parentDir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: parentDir,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: parentDir.path)
        if createBackup, let current = try? Data(contentsOf: fileURL) {
            try preserve(current, at: backupURL)
        }
        let data = try JSONSerialization.data(
            withJSONObject: dict,
            options: [.prettyPrinted, .sortedKeys]
        )
        try data.write(to: fileURL, options: .atomic)
        enforcePermissions()
    }

    private func preserve(_ data: Data, at url: URL) throws {
        try data.write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    private func enforcePermissions() {
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }
}

public extension Notification.Name {
    static let settingsStoreError = Notification.Name("Ecran.settingsStoreError")
    static let settingsDidChange = Notification.Name("Ecran.settingsDidChange")
    static let permissionsDidChange = Notification.Name("Ecran.permissionsDidChange")
    static let hotkeySettingsChanged = Notification.Name("Ecran.hotkeySettingsChanged")
}
