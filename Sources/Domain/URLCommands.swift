import Foundation

public enum URLTask: String, Sendable {
    case ignoreApp = "ignore-app"
    case unignoreApp = "unignore-app"
}

public struct URLCommand: Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        case action(WindowAction)
        case task(URLTask, bundleID: String?)
        case settings
    }

    public var kind: Kind

    public init(kind: Kind) {
        self.kind = kind
    }

    public static func parse(url: URL) -> URLCommand? {
        guard url.scheme?.lowercased() == "ecran" || url.scheme?.lowercased() == "rectangle" else {
            return nil
        }
        let host = url.host?.lowercased() ?? ""
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let name = items.first(where: { $0.name == "name" })?.value ?? ""
        let bundleID = items.first(where: { $0.name == "app-bundle-id" })?.value
        switch host {
        case "execute-action":
            guard let action = WindowAction.parse(name: name) else { return nil }
            return URLCommand(kind: .action(action))
        case "execute-task":
            guard let task = URLTask(rawValue: name) else { return nil }
            return URLCommand(kind: .task(task, bundleID: bundleID))
        case "settings":
            return URLCommand(kind: .settings)
        default:
            return nil
        }
    }
}
