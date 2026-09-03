import AppKit
import Domain
import Infrastructure
import SwiftUI

private enum SwitcherChrome {
    static let panelRadius: CGFloat = 16
    static let rowRadius: CGFloat = 10
}

struct SwitcherView: View {
    @Bindable var model: SwitcherModel
    let settings: AppSettings
    @State private var hoveredIndex: Int?

    private var palette: SwitcherPalette { settings.colorScheme.palette }
    private var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: SwitcherChrome.panelRadius, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if settings.switcherHeaderStyle == .default {
                header
            }
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 2) {
                        rows
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, settings.switcherHeaderStyle == .default ? 4 : 8)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: model.selection) { _, index in
                    withAnimation(.easeOut(duration: 0.14)) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
        }
        .frame(width: SwitcherPanel.metrics.width, height: SwitcherPanel.metrics.height)
        .background {
            panelShape.fill(.ultraThinMaterial)
            panelShape.fill(Color.black.opacity(0.42))
        }
        .overlay {
            panelShape.strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        }
        .clipShape(panelShape)
        .compositingGroup()
        .shadow(color: .black.opacity(0.45), radius: 28, y: 12)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: model.kind == .sameApp ? "rectangle.2.swap" : "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(primaryColor)
                .frame(width: 22)
            Text(model.kind == .sameApp ? "Windows" : "Apps")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
            Text(headerDetail)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(EcranChrome.tertiaryText)
            Spacer(minLength: 8)
            Text("↩")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(EcranChrome.tertiaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private var headerDetail: String {
        switch model.kind {
        case .sameApp:
            SwitcherPresentation.windowCountLabel(model.windows.count)
        case .apps:
            model.apps.count == 1 ? "1 app" : "\(model.apps.count) apps"
        }
    }

    @ViewBuilder
    private var rows: some View {
        switch model.kind {
        case .sameApp:
            ForEach(Array(model.windows.enumerated()), id: \.offset) { index, window in
                SwitcherListRow(
                    title: window.projectName.isEmpty ? window.title : window.projectName,
                    subtitle: subtitle(for: window),
                    selected: index == model.selection,
                    hovering: hoveredIndex == index,
                    badge: badge(index),
                    accent: primaryColor,
                    artwork: {
                        SwitcherArtwork(
                            style: settings.windowDisplayStyle,
                            monogram: Monogram.from(title: window.projectName.isEmpty ? window.appName : window.projectName),
                            appIcon: WindowCatalog.appIcon(for: window.processID),
                            preview: model.previews[window.windowID],
                            accent: primaryColor
                        )
                    },
                    metrics: {
                        SwitcherWindowMetrics(
                            isMinimized: window.isMinimized,
                            isOnOtherSpace: window.isOnOtherSpace,
                            spaceIndex: window.spaceIndex
                        )
                    }
                )
                .id(index)
                .onHover { hovering in
                    hoveredIndex = hovering ? index : nil
                }
                .onTapGesture {
                    model.choose(index)
                }
            }
        case .apps:
            ForEach(Array(model.apps.enumerated()), id: \.offset) { index, app in
                SwitcherListRow(
                    title: app.appName,
                    subtitle: SwitcherPresentation.windowCountLabel(app.windowCount),
                    selected: index == model.selection,
                    hovering: hoveredIndex == index,
                    badge: badge(index),
                    accent: primaryColor,
                    artwork: {
                        SwitcherArtwork(
                            style: settings.windowDisplayStyle == .preview ? .appIcon : settings.windowDisplayStyle,
                            monogram: Monogram.from(title: app.appName),
                            appIcon: WindowCatalog.appIcon(for: app.processID),
                            preview: nil,
                            accent: primaryColor
                        )
                    },
                    metrics: {
                        SwitcherAppMetrics(isActive: app.isActive)
                    }
                )
                .id(index)
                .onHover { hovering in
                    hoveredIndex = hovering ? index : nil
                }
                .onTapGesture {
                    model.choose(index)
                }
            }
        }
    }

    private func badge(_ index: Int) -> String? {
        guard settings.showNumberKeys, index < 9 else { return nil }
        return "\(index + 1)"
    }

    private func subtitle(for window: WindowRecord) -> String? {
        if window.projectName != window.title, !window.title.isEmpty {
            return window.title
        }
        return nil
    }

    private var primaryColor: Color {
        if palette.usesSystemAccent {
            return Color.accentColor
        }
        return Color(red: palette.primaryRed, green: palette.primaryGreen, blue: palette.primaryBlue)
    }
}

struct SwitcherListRow<Artwork: View, Metrics: View>: View {
    let title: String
    let subtitle: String?
    let selected: Bool
    let hovering: Bool
    let badge: String?
    let accent: Color
    @ViewBuilder var artwork: () -> Artwork
    @ViewBuilder var metrics: () -> Metrics

    private var rowShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: SwitcherChrome.rowRadius, style: .continuous)
    }

    var body: some View {
        HStack(spacing: 12) {
            artwork()
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(EcranChrome.secondaryText)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            metrics()
            if let badge {
                SwitcherIndexMark(text: badge, emphasized: selected)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .background {
            if selected {
                rowShape.fill(Color.white.opacity(0.14))
            } else if hovering {
                rowShape.fill(Color.white.opacity(0.06))
            }
        }
        .animation(.easeOut(duration: 0.12), value: selected)
        .animation(.easeOut(duration: 0.12), value: hovering)
        .contentShape(rowShape)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct SwitcherArtwork: View {
    let style: WindowDisplayStyle
    let monogram: Monogram
    let appIcon: NSImage?
    let preview: NSImage?
    let accent: Color

    private var wellShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
    }

    var body: some View {
        switch style {
        case .appIcon:
            icon(size: 28)
                .clipShape(wellShape)
        case .initials:
            Text(monogram.initials)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color(hue: monogram.hue, saturation: 0.46, brightness: 0.72), in: wellShape)
        case .preview:
            if let preview {
                ZStack(alignment: .bottomTrailing) {
                    Image(nsImage: preview)
                        .resizable()
                        .scaledToFill()
                    icon(size: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        .padding(4)
                }
                .frame(width: 72, height: 46)
                .clipShape(wellShape)
            } else {
                icon(size: 28)
                    .clipShape(wellShape)
            }
        }
    }

    @ViewBuilder
    private func icon(size: CGFloat) -> some View {
        if let appIcon {
            Image(nsImage: appIcon)
                .resizable()
                .interpolation(.high)
                .frame(width: size, height: size)
        } else {
            Image(systemName: "app.dashed")
                .font(.system(size: size * 0.62, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: size, height: size)
        }
    }
}

struct SwitcherWindowMetrics: View {
    let isMinimized: Bool
    let isOnOtherSpace: Bool
    let spaceIndex: Int

    var body: some View {
        HStack(spacing: 6) {
            if isMinimized {
                SwitcherMetricChip(symbol: "dock.rectangle", text: "Dock")
            } else if isOnOtherSpace {
                SwitcherDesktopGlyph(spaceIndex: spaceIndex)
                if let label = SwitcherPresentation.spaceLabel(isOnOtherSpace: true, spaceIndex: spaceIndex) {
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(EcranChrome.secondaryText)
                }
            }
        }
    }
}

struct SwitcherAppMetrics: View {
    let isActive: Bool

    var body: some View {
        if isActive {
            Text("Front")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(EcranChrome.secondaryText)
        }
    }
}

struct SwitcherMetricChip: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(EcranChrome.secondaryText)
    }
}

struct SwitcherDesktopGlyph: View {
    let spaceIndex: Int

    var body: some View {
        let highlight = spaceIndex > 0 ? (spaceIndex - 1) % 6 : 0
        VStack(spacing: 2) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { column in
                        let index = row * 3 + column
                        RoundedRectangle(cornerRadius: 1.4, style: .continuous)
                            .fill(index == highlight ? Color.white.opacity(0.78) : Color.white.opacity(0.18))
                            .frame(width: 5, height: 4)
                    }
                }
            }
        }
        .accessibilityLabel(SwitcherPresentation.spaceLabel(isOnOtherSpace: true, spaceIndex: spaceIndex) ?? "Other desktop")
    }
}

struct SwitcherIndexMark: View {
    let text: String
    var emphasized = false

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(emphasized ? Color.white : EcranChrome.tertiaryText)
            .frame(minWidth: 20, minHeight: 20)
            .background(
                Color.white.opacity(emphasized ? 0.16 : 0.06),
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
    }
}
