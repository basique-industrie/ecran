import Foundation

public enum ModifierKey: String, CaseIterable, Codable, Sendable {
    case command
    case option
    case control
    case function

    public var displayName: String {
        switch self {
        case .command: "Command"
        case .option: "Option"
        case .control: "Control"
        case .function: "Fn"
        }
    }

    public var glyph: String {
        switch self {
        case .command: "⌘"
        case .option: "⌥"
        case .control: "⌃"
        case .function: "fn"
        }
    }

    public var carbonModifier: UInt32 {
        switch self {
        case .command: 256
        case .option: 2048
        case .control: 4096
        case .function: 131_072
        }
    }

    public var eventModifierRawValue: UInt {
        switch self {
        case .command: 1 << 20
        case .option: 1 << 19
        case .control: 1 << 18
        case .function: 1 << 23
        }
    }
}

public enum TriggerKey: String, CaseIterable, Codable, Sendable {
    case grave = "`"
    case tab = "Tab"
    case space = "Space"
    case semicolon = ";"
    case quote = "'"
    case comma = ","
    case period = "."
    case slash = "/"
    case backslash = "\\"
    case leftBracket = "["
    case rightBracket = "]"

    public var displayName: String {
        switch self {
        case .grave: "`"
        case .tab: "Tab"
        case .space: "Space"
        case .semicolon: ";"
        case .quote: "'"
        case .comma: ","
        case .period: "."
        case .slash: "/"
        case .backslash: "\\"
        case .leftBracket: "["
        case .rightBracket: "]"
        }
    }

    public var keyCode: UInt32 {
        switch self {
        case .grave: 50
        case .tab: 48
        case .space: 49
        case .semicolon: 41
        case .quote: 39
        case .comma: 43
        case .period: 47
        case .slash: 44
        case .backslash: 42
        case .leftBracket: 33
        case .rightBracket: 30
        }
    }
}

public struct KeyChord: Hashable, Codable, Sendable {
    public var keyCode: UInt16
    public var modifierFlags: UInt

    public init(keyCode: UInt16, modifierFlags: UInt) {
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
    }

    public static func optionControl(_ keyCode: UInt16) -> KeyChord {
        KeyChord(keyCode: keyCode, modifierFlags: ModifierKey.option.eventModifierRawValue | ModifierKey.control.eventModifierRawValue)
    }

    public static func optionControlShift(_ keyCode: UInt16) -> KeyChord {
        KeyChord(
            keyCode: keyCode,
            modifierFlags: ModifierKey.option.eventModifierRawValue
                | ModifierKey.control.eventModifierRawValue
                | (1 << 17)
        )
    }

    public static func optionControlCommand(_ keyCode: UInt16) -> KeyChord {
        KeyChord(
            keyCode: keyCode,
            modifierFlags: ModifierKey.option.eventModifierRawValue
                | ModifierKey.control.eventModifierRawValue
                | ModifierKey.command.eventModifierRawValue
        )
    }
}

public enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case system
    case english

    public var displayName: String {
        switch self {
        case .system: "System"
        case .english: "English"
        }
    }

    public func applyPreferredLanguages() {
        switch self {
        case .system:
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        case .english:
            UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        }
    }
}
