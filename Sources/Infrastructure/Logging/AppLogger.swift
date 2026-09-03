import Foundation
import OSLog

public enum AppLog {
    public static let ui = CategoryLogger(category: "ui")
    public static let switcher = CategoryLogger(category: "switcher")
    public static let windows = CategoryLogger(category: "windows")
    public static let hotkeys = CategoryLogger(category: "hotkeys")
    public static let snap = CategoryLogger(category: "snap")
    public static let settings = CategoryLogger(category: "settings")

    public static func openLogsDirectory() {
        FileLogger.shared.openLogsDirectory()
    }

    public static func openCurrentLogFile() {
        FileLogger.shared.openCurrentLogFile()
    }

    public static func clearLogs() {
        FileLogger.shared.clear()
    }

    public static func exportCurrentLog(to destination: URL) throws {
        try FileLogger.shared.exportCurrentLog(to: destination)
    }

    public static var logsDirectoryURL: URL {
        FileLogger.shared.logsDirectory
    }
}

public struct CategoryLogger: Sendable {
    private let category: String
    private let osLogger: Logger

    init(category: String) {
        self.category = category
        let subsystem = Bundle.main.bundleIdentifier ?? AppIdentity.shippedBundleIdentifier
        self.osLogger = Logger(subsystem: subsystem, category: category)
    }

    public func debug(_ message: String) {
        osLogger.debug("\(message, privacy: .private)")
    }

    public func info(_ message: String) {
        osLogger.info("\(message, privacy: .private)")
        FileLogger.shared.log(.info, category: category, message: message)
    }

    public func notice(_ message: String) {
        osLogger.notice("\(message, privacy: .private)")
        FileLogger.shared.log(.info, category: category, message: message)
    }

    public func warning(_ message: String) {
        osLogger.warning("\(message, privacy: .private)")
        FileLogger.shared.log(.warning, category: category, message: message)
    }

    public func error(_ message: String) {
        osLogger.error("\(message, privacy: .private)")
        FileLogger.shared.log(.error, category: category, message: message)
    }
}
