import Foundation

public enum WindowClassification {
    public static let standardSubrole = "AXStandardWindow"
    public static let dialogSubrole = "AXDialog"
    public static let floatingSubrole = "AXFloatingWindow"
    public static let systemDialogSubrole = "AXSystemDialog"
    public static let unknownSubrole = "AXUnknown"

    public static func acceptsWindowSubrole(_ subrole: String?) -> Bool {
        switch subrole {
        case nil, standardSubrole, dialogSubrole:
            true
        default:
            false
        }
    }

    public static func isSteamApplication(_ bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        if bundleID == "com.valvesoftware.steam" { return true }
        return bundleID.hasPrefix("com.valvesoftware.")
            || bundleID.contains("steamapps")
            || bundleID.contains("steam")
    }

    public static func isValidWindowLayer(_ layer: Int, forBundleID bundleID: String?) -> Bool {
        if layer == 0 { return true }
        return isSteamApplication(bundleID) && (1...100).contains(layer)
    }
}

public struct Monogram: Hashable, Sendable {
    public var initials: String
    public var hue: Double

    public init(initials: String, hue: Double) {
        self.initials = initials
        self.hue = hue
    }

    public static func from(title: String) -> Monogram {
        let words = title.split { " -_/.|—".contains($0) }.filter { !$0.isEmpty }
        let initials: String
        if words.count >= 2 {
            initials = String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        } else if let first = title.first, !first.isWhitespace {
            initials = String(first).uppercased()
        } else {
            initials = "?"
        }
        var hash: UInt64 = 5381
        for unit in title.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(unit)
        }
        let hue = Double(hash % 360) / 360
        return Monogram(initials: initials, hue: hue)
    }
}
