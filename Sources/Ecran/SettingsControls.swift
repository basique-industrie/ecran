import AppKit
import Domain
import SwiftUI

@MainActor
enum SettingsAlert {
    static func show(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}

struct EcranToggle: View {
    @Binding var isOn: Bool
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.16)) { isOn.toggle() }
        } label: {
            Capsule(style: .continuous)
                .fill(isOn ? Color.white.opacity(0.48) : Color.white.opacity(0.1))
                .frame(width: 32, height: 18)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .frame(width: 14, height: 14)
                        .padding(2)
                }
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .brightness(isHovering && isEnabled ? 0.08 : 0)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

struct SettingsToggleRow: View {
    let title: String
    var detail: String? = nil
    var disabled = false
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                if let detail {
                    Text(detail)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(EcranChrome.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            EcranToggle(isOn: $isOn)
                .disabled(disabled)
                .accessibilityLabel(title)
        }
        .padding(.vertical, 3)
        .opacity(disabled ? 0.55 : 1)
    }
}

struct EcranSegmentBar<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    var title: (Item) -> String
    var symbol: ((Item) -> String)?
    var equalWidth = true

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items, id: \.self) { item in
                let selected = item == selection
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        selection = item
                    }
                } label: {
                    HStack(spacing: 6) {
                        if let symbol {
                            Image(systemName: symbol(item))
                                .font(.system(size: 11, weight: .semibold))
                        }
                        Text(title(item))
                            .font(.system(size: 12, weight: selected ? .semibold : .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(selected ? Color.white : EcranChrome.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(maxWidth: equalWidth ? .infinity : nil)
                    .background {
                        if selected {
                            Capsule(style: .continuous)
                                .fill(EcranChrome.selectedFill)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title(item))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Color.black.opacity(0.35), in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(EcranChrome.hairline, lineWidth: 1)
        }
    }
}

enum SettingsButtonProminence {
    case primary
    case secondary
}

struct QuietButton: View {
    let title: String
    var symbol: String? = nil
    var prominence: SettingsButtonProminence = .secondary
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 10, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .frame(minHeight: EcranChrome.buttonHeight)
            .background(
                background,
                in: RoundedRectangle(cornerRadius: EcranChrome.fieldRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: EcranChrome.fieldRadius, style: .continuous)
                    .strokeBorder(border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .opacity(isEnabled ? 1 : 0.4)
        .animation(.easeOut(duration: 0.12), value: isHovering)
    }

    private var foreground: Color {
        switch prominence {
        case .primary: .white
        case .secondary: isHovering ? .white : EcranChrome.secondaryText
        }
    }

    private var background: Color {
        if isHovering { return Color.white.opacity(prominence == .primary ? 0.18 : 0.08) }
        return prominence == .primary ? Color.white.opacity(0.13) : EcranChrome.fieldFill
    }

    private var border: Color {
        switch prominence {
        case .primary: Color.white.opacity(isHovering ? 0.28 : 0.2)
        case .secondary: isHovering ? EcranChrome.controlBorder : EcranChrome.hairline
        }
    }
}

struct SettingsSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1

    var body: some View {
        GeometryReader { proxy in
            let thumbSize: CGFloat = 16
            let travel = max(proxy.size.width - thumbSize, 1)
            let thumbCenter = thumbSize / 2 + travel * fraction

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(EcranChrome.controlBorder)
                    .frame(height: 5)
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.48))
                    .frame(width: max(thumbCenter, 5), height: 5)
                Circle()
                    .fill(Color.white.opacity(0.94))
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                    .position(x: thumbCenter, y: proxy.size.height / 2)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        setFraction((gesture.location.x - thumbSize / 2) / travel)
                    }
            )
        }
        .frame(height: 20)
    }

    private var fraction: CGFloat {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return CGFloat(min(max((value - range.lowerBound) / span, 0), 1))
    }

    private func setFraction(_ fraction: CGFloat) {
        let clamped = min(max(Double(fraction), 0), 1)
        let proposed = range.lowerBound + clamped * (range.upperBound - range.lowerBound)
        let stepped = range.lowerBound + ((proposed - range.lowerBound) / step).rounded() * step
        value = min(max(stepped, range.lowerBound), range.upperBound)
    }
}

struct SettingsSliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var display: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .frame(minWidth: 110, alignment: .leading)
            SettingsSlider(value: $value, range: range, step: step)
            Text(display)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(EcranChrome.secondaryText)
                .monospacedDigit()
                .frame(minWidth: 36, alignment: .trailing)
        }
    }
}

struct SettingsNumericRow: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
            Spacer(minLength: 12)
            TextField("", value: $value, format: .number)
                .ecranFieldChrome()
                .frame(width: 88)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct SettingsPickerRow<Item: Hashable>: View {
    let title: String
    @Binding var selection: Item
    let items: [Item]
    var label: (Item) -> String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
            Spacer(minLength: 8)
            Menu {
                ForEach(items, id: \.self) { item in
                    Button(label(item)) {
                        selection = item
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(label(selection))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(EcranChrome.tertiaryText)
                }
                .padding(.horizontal, 10)
                .frame(minHeight: 30)
                .background(
                    EcranChrome.fieldFill,
                    in: RoundedRectangle(cornerRadius: EcranChrome.fieldRadius, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: EcranChrome.fieldRadius, style: .continuous)
                        .strokeBorder(EcranChrome.controlBorder, lineWidth: 1)
                }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.vertical, 2)
    }
}

struct StatusChip: View {
    let text: String
    var emphasis: Color = EcranChrome.secondaryText

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(emphasis)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(emphasis.opacity(0.14), in: Capsule(style: .continuous))
    }
}

struct PermissionRow: View {
    let title: String
    let granted: Bool
    let required: Bool
    var needsRelaunch: Bool = false
    let grant: () -> Void
    var relaunch: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            SettingsGlyph(
                symbol: granted ? "checkmark.shield.fill" : "lock.shield",
                size: 34
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                Text(required ? "Required" : "Optional")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(EcranChrome.tertiaryText)
            }
            Spacer(minLength: 8)
            StatusChip(
                text: statusTitle,
                emphasis: statusEmphasis
            )
            if !granted {
                QuietButton(title: "Grant", symbol: "lock.open", prominence: .primary, action: grant)
            }
            if needsRelaunch, let relaunch {
                QuietButton(title: "Restart", symbol: "arrow.clockwise", prominence: .primary, action: relaunch)
            }
        }
        .padding(.vertical, 2)
    }

    private var statusTitle: String {
        if needsRelaunch { return "Restart" }
        return granted ? "Granted" : "Not granted"
    }

    private var statusEmphasis: Color {
        if needsRelaunch { return Color.orange.opacity(0.95) }
        return granted ? Color.white.opacity(0.82) : Color.orange.opacity(0.95)
    }
}

struct Keycap: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .frame(minWidth: 28, minHeight: 26)
            .background(
                EcranChrome.fieldFill,
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(EcranChrome.controlBorder, lineWidth: 1)
            }
    }
}

struct DisplayStylePicker: View {
    @Binding var selection: WindowDisplayStyle

    var body: some View {
        HStack(spacing: 10) {
            ForEach(WindowDisplayStyle.allCases, id: \.self) { style in
                let selected = style == selection
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        selection = style
                    }
                } label: {
                    VStack(spacing: 10) {
                        stylePreview(style)
                        Text(style.displayName)
                            .font(.system(size: 12, weight: selected ? .semibold : .medium))
                    }
                    .foregroundStyle(selected ? Color.white : EcranChrome.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        selected ? EcranChrome.selectedFill : EcranChrome.fieldFill,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                selected ? EcranChrome.selectionBorder : EcranChrome.controlBorder,
                                lineWidth: 1
                            )
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(style.displayName)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    @ViewBuilder
    private func stylePreview(_ style: WindowDisplayStyle) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .frame(width: 44, height: 32)
            switch style {
            case .appIcon:
                Image(systemName: "app.fill")
                    .font(.system(size: 15, weight: .semibold))
            case .initials:
                Text("EC")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            case .preview:
                Image(systemName: "eye")
                    .font(.system(size: 14, weight: .semibold))
            }
        }
    }
}

struct ColorSchemeSwatch: View {
    let scheme: SwitcherColorScheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                swatch
                    .frame(width: 26, height: 26)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                isSelected ? Color.white.opacity(0.92) : Color.white.opacity(0.14),
                                lineWidth: isSelected ? 2 : 1
                            )
                    }
                Text(scheme.displayName)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.white : EcranChrome.tertiaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected ? EcranChrome.selectedFill : Color.clear,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isSelected ? EcranChrome.selectionBorder : Color.clear,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .help(scheme.displayName)
        .accessibilityLabel(scheme.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var swatch: some View {
        let palette = scheme.palette
        if palette.usesSystemAccent {
            Image(systemName: "circle.lefthalf.filled")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white.opacity(0.86))
        } else {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: palette.primaryRed, green: palette.primaryGreen, blue: palette.primaryBlue),
                            Color(red: palette.secondaryRed, green: palette.secondaryGreen, blue: palette.secondaryBlue),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

struct SnapZonePreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    zone("↖", "Quarter")
                    zone("↑", "Maximize")
                    zone("↗", "Quarter")
                }
                .frame(height: 40)
                HStack(spacing: 4) {
                    zone("←", "Half")
                    zone("→", "Half")
                }
                .frame(height: 96)
                HStack(spacing: 4) {
                    zone("⅓", "Third")
                    zone("⅓", "Third")
                    zone("⅓", "Third")
                }
                .frame(height: 40)
            }
            .padding(8)
            .background(
                Color.black.opacity(0.28),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(EcranChrome.controlBorder, lineWidth: 1)
            }
        }
    }

    private func zone(_ glyph: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(glyph)
                .font(.system(size: 13, weight: .semibold))
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(EcranChrome.secondaryText)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            EcranChrome.fieldFill,
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }
}

struct CycleSizeChip: View {
    let size: CycleSize
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Text(size.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isOn ? Color.white : EcranChrome.secondaryText)
                .padding(.horizontal, 10)
                .frame(minHeight: 28)
                .background(
                    isOn ? EcranChrome.selectedFill : EcranChrome.fieldFill,
                    in: Capsule(style: .continuous)
                )
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(isOn ? EcranChrome.selectionBorder : EcranChrome.controlBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}
