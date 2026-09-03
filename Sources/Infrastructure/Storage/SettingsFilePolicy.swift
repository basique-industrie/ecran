import Foundation

public enum SettingsFilePolicy {
    public static let maxImportBytes = 2 * 1024 * 1024

    public enum LoadError: LocalizedError, Equatable {
        case worldWritable
        case tooLarge
        case unreadable

        public var errorDescription: String? {
            switch self {
            case .worldWritable:
                "This file is writable by other users, so Ecran will not read it."
            case .tooLarge:
                "This file is larger than 2 MB."
            case .unreadable:
                "This file could not be read."
            }
        }
    }

    public static func isWorldWritable(_ url: URL) -> Bool {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        guard let permissions = attributes?[.posixPermissions] as? NSNumber else { return false }
        return permissions.intValue & 0o002 != 0
    }

    public static func readJSON(at url: URL) throws -> Data {
        if isWorldWritable(url) { throw LoadError.worldWritable }
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        if let size = values.fileSize, size > maxImportBytes {
            throw LoadError.tooLarge
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            throw LoadError.unreadable
        }
    }
}
