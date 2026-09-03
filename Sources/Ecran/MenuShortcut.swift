import AppKit
import Domain
import Infrastructure

enum MenuShortcut {
    static func apply(_ chord: KeyChord?, to item: NSMenuItem) {
        guard let chord, let equivalent = equivalent(for: chord) else {
            clear(item)
            return
        }
        item.keyEquivalent = equivalent.key
        item.keyEquivalentModifierMask = equivalent.modifiers
    }

    static func clear(_ item: NSMenuItem) {
        item.keyEquivalent = ""
        item.keyEquivalentModifierMask = []
    }

    static func equivalent(for chord: KeyChord) -> (key: String, modifiers: NSEvent.ModifierFlags)? {
        guard let key = keyEquivalent(for: chord.keyCode) else { return nil }
        return (key, NSEvent.ModifierFlags(rawValue: chord.modifierFlags))
    }

    static func keyEquivalent(for keyCode: UInt16) -> String? {
        switch keyCode {
        case 36, 76:
            "\r"
        case 48:
            "\t"
        case 49:
            " "
        case 51:
            String(UnicodeScalar(NSBackspaceCharacter)!)
        case 53:
            String(UnicodeScalar(0x1B)!)
        case 123:
            String(UnicodeScalar(NSLeftArrowFunctionKey)!)
        case 124:
            String(UnicodeScalar(NSRightArrowFunctionKey)!)
        case 125:
            String(UnicodeScalar(NSDownArrowFunctionKey)!)
        case 126:
            String(UnicodeScalar(NSUpArrowFunctionKey)!)
        case 122:
            String(UnicodeScalar(NSF1FunctionKey)!)
        case 120:
            String(UnicodeScalar(NSF2FunctionKey)!)
        case 99:
            String(UnicodeScalar(NSF3FunctionKey)!)
        case 118:
            String(UnicodeScalar(NSF4FunctionKey)!)
        case 96:
            String(UnicodeScalar(NSF5FunctionKey)!)
        case 97:
            String(UnicodeScalar(NSF6FunctionKey)!)
        case 98:
            String(UnicodeScalar(NSF7FunctionKey)!)
        case 100:
            String(UnicodeScalar(NSF8FunctionKey)!)
        case 101:
            String(UnicodeScalar(NSF9FunctionKey)!)
        case 109:
            String(UnicodeScalar(NSF10FunctionKey)!)
        case 103:
            String(UnicodeScalar(NSF11FunctionKey)!)
        case 111:
            String(UnicodeScalar(NSF12FunctionKey)!)
        default:
            KeyboardLayout.character(for: UInt32(keyCode))?.lowercased()
        }
    }
}
