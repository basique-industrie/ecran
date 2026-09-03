import Carbon
import Domain
import Foundation

public enum KeyboardLayout {
    public static func specialKeyLabel(for keyCode: UInt16) -> String? {
        switch keyCode {
        case 123: "←"
        case 124: "→"
        case 125: "↓"
        case 126: "↑"
        case 36, 76: "↩"
        case 51: "⌫"
        case 48: "⇥"
        case 49: "Space"
        case 53: "⎋"
        default: nil
        }
    }

    public static func character(for keyCode: UInt32) -> String? {
        if let special = specialKeyLabel(for: UInt16(keyCode)) {
            return special
        }
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let raw = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else {
            return nil
        }
        let data = Unmanaged<CFData>.fromOpaque(raw).takeUnretainedValue() as Data
        return data.withUnsafeBytes { buffer -> String? in
            guard let layout = buffer.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else {
                return nil
            }
            var deadKeyState: UInt32 = 0
            var length = 0
            var chars = [UniChar](repeating: 0, count: 4)
            let status = UCKeyTranslate(
                layout,
                UInt16(keyCode),
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                4,
                &length,
                &chars
            )
            guard status == noErr, length > 0 else { return nil }
            let value = String(utf16CodeUnits: chars, count: length)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard value.unicodeScalars.contains(where: { $0.value >= 0x21 && $0.value != 0x7F }) else {
                return nil
            }
            return value.uppercased()
        }
    }

    public static func label(for trigger: TriggerKey) -> String {
        character(for: trigger.keyCode) ?? trigger.displayName
    }

    public static func displayLabel(for chord: KeyChord) -> String {
        var parts: [String] = []
        if chord.modifierFlags & (1 << 18) != 0 { parts.append("⌃") }
        if chord.modifierFlags & (1 << 19) != 0 { parts.append("⌥") }
        if chord.modifierFlags & (1 << 17) != 0 { parts.append("⇧") }
        if chord.modifierFlags & (1 << 20) != 0 { parts.append("⌘") }
        parts.append(character(for: UInt32(chord.keyCode)) ?? "•")
        return parts.joined()
    }
}
