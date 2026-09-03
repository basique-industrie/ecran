import AppKit
import SwiftUI

enum EcranChrome {
    static let cardRadius: CGFloat = 14
    static let fieldRadius: CGFloat = 8
    static let pageInset: CGFloat = 22
    static let stackSpacing: CGFloat = 18
    static let columnSpacing: CGFloat = 16
    static let buttonHeight: CGFloat = 30
    static let headerControlSize: CGFloat = 28
    static let hairline = Color.white.opacity(0.08)
    static let cardFill = Color.white.opacity(0.04)
    static let fieldFill = Color.white.opacity(0.06)
    static let selectedFill = Color.white.opacity(0.1)
    static let hoverFill = Color.white.opacity(0.09)
    static let controlBorder = Color.white.opacity(0.1)
    static let selectionBorder = Color.white.opacity(0.2)
    static let secondaryText = Color.white.opacity(0.68)
    static let tertiaryText = Color.white.opacity(0.52)
    static let popoverNSColor = NSColor(calibratedWhite: 0.09, alpha: 1)
}

struct SettingsHairline: View {
    var body: some View {
        Rectangle()
            .fill(EcranChrome.hairline)
            .frame(height: 1)
    }
}

struct PageTitle: View {
    let title: String
    var subtitle: String? = nil
    var symbol: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if let symbol {
                SettingsGlyph(symbol: symbol, size: 36)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                if let subtitle {
                    SettingsCaption(text: subtitle)
                }
            }
        }
    }
}

struct SettingsGlyph: View {
    let symbol: String
    var size: CGFloat = 32

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size < 34 ? 13 : 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                EcranChrome.fieldFill,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(EcranChrome.controlBorder, lineWidth: 1)
            }
    }
}

struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(EcranChrome.secondaryText)
    }
}

struct FieldLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(EcranChrome.secondaryText)
    }
}

struct SettingsCaption: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(EcranChrome.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct SettingsNotice: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 11, weight: .semibold))
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(EcranChrome.secondaryText)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            EcranChrome.fieldFill,
            in: RoundedRectangle(cornerRadius: EcranChrome.fieldRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: EcranChrome.fieldRadius, style: .continuous)
                .strokeBorder(EcranChrome.controlBorder, lineWidth: 1)
        }
    }
}

struct SettingsPage<Content: View>: View {
    var alignment: Alignment = .topLeading
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EcranChrome.stackSpacing) {
                content()
            }
            .padding(EcranChrome.pageInset)
            .frame(maxWidth: .infinity, alignment: alignment)
        }
        .scrollIndicators(.automatic)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: EcranChrome.popoverNSColor))
    }
}

struct SettingsColumns<Left: View, Right: View>: View {
    var spacing: CGFloat = EcranChrome.columnSpacing
    @ViewBuilder var left: () -> Left
    @ViewBuilder var right: () -> Right

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            VStack(alignment: .leading, spacing: EcranChrome.stackSpacing) {
                left()
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            VStack(alignment: .leading, spacing: EcranChrome.stackSpacing) {
                right()
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var symbol: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    if let symbol {
                        Image(systemName: symbol)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(EcranChrome.secondaryText)
                    }
                    SectionLabel(title: title)
                }
                if let subtitle {
                    SettingsCaption(text: subtitle)
                }
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsCard<Content: View>: View {
    var padding: CGFloat = 14
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                EcranChrome.cardFill,
                in: RoundedRectangle(cornerRadius: EcranChrome.cardRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: EcranChrome.cardRadius, style: .continuous)
                    .strokeBorder(EcranChrome.hairline.opacity(0.85), lineWidth: 1)
            }
    }
}

struct SettingsFeatureTile: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsGlyph(symbol: symbol, size: 32)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
            Text(detail)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(EcranChrome.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            EcranChrome.cardFill,
            in: RoundedRectangle(cornerRadius: EcranChrome.cardRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: EcranChrome.cardRadius, style: .continuous)
                .strokeBorder(EcranChrome.hairline.opacity(0.85), lineWidth: 1)
        }
    }
}

struct MetricPair: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(EcranChrome.secondaryText)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }
}

struct SettingsDisclosure<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @State private var isExpanded: Bool
    @ViewBuilder var content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        expanded: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        _isExpanded = State(initialValue: expanded)
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.16)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 9) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                        if let subtitle {
                            Text(subtitle)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(EcranChrome.secondaryText)
                                .lineLimit(2)
                        }
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(EcranChrome.tertiaryText)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title), \(isExpanded ? "expanded" : "collapsed")")

            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 2)
    }
}

struct SettingsFieldChrome: ViewModifier {
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .frame(minHeight: 30)
            .focused($isFocused)
            .background(
                EcranChrome.fieldFill,
                in: RoundedRectangle(cornerRadius: EcranChrome.fieldRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: EcranChrome.fieldRadius, style: .continuous)
                    .strokeBorder(isFocused ? EcranChrome.selectionBorder : EcranChrome.controlBorder, lineWidth: 1)
            }
    }
}

extension View {
    func ecranFieldChrome() -> some View {
        modifier(SettingsFieldChrome())
    }
}

/// About-page mark: the three window panes fill the rounded square, like Iles.
struct EcranAppMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.black)
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(EcranChrome.hairline, lineWidth: 1)
            HStack(spacing: 3.5) {
                RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.92), lineWidth: 2)
                    .frame(width: 18, height: 38)
                VStack(spacing: 3.5) {
                    RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.92), lineWidth: 2)
                        .frame(width: 18, height: 17.25)
                    RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.92), lineWidth: 2)
                        .frame(width: 18, height: 17.25)
                }
            }
        }
        .shadow(color: .black.opacity(0.28), radius: 8, y: 3)
        .accessibilityHidden(true)
    }
}
