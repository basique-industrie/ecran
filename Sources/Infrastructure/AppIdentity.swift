import Foundation

public struct AppIdentity: Sendable, Equatable {
    public static let shippedBundleIdentifier = "com.jean.ecran"
    public static let developmentBundleIdentifier = "com.jean.ecran.dev"

    public static let shipped = AppIdentity(bundleIdentifier: shippedBundleIdentifier)
    public static let development = AppIdentity(bundleIdentifier: developmentBundleIdentifier)
    public static let current = AppIdentity()

    public let bundleIdentifier: String
    public let isDevelopment: Bool
    public let displayName: String
    public let dataDirectoryName: String
    public let logDirectoryName: String
    public let logFileName: String

    public init(bundleIdentifier: String = Bundle.main.bundleIdentifier ?? shippedBundleIdentifier) {
        self.bundleIdentifier = bundleIdentifier
        let isDevelopment = bundleIdentifier == Self.developmentBundleIdentifier
        self.isDevelopment = isDevelopment
        if isDevelopment {
            displayName = "Ecran Dev"
            dataDirectoryName = ".ecran-dev"
            logDirectoryName = "Ecran-Dev"
            logFileName = "Ecran-Dev.log"
        } else {
            displayName = "Ecran"
            dataDirectoryName = ".ecran"
            logDirectoryName = "Ecran"
            logFileName = "Ecran.log"
        }
    }

    public var dataDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(dataDirectoryName, isDirectory: true)
    }

    public var settingsFileURL: URL {
        dataDirectory.appendingPathComponent("settings.json")
    }

    public var logsDirectory: URL {
        let libraryDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library", isDirectory: true)
        return libraryDirectory
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent(logDirectoryName, isDirectory: true)
    }

    public var logFileURL: URL {
        logsDirectory.appendingPathComponent(logFileName)
    }

    public var openSettingsNotification: Notification.Name {
        Notification.Name(bundleIdentifier + ".openSettings")
    }
}
