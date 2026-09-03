import AppKit
import Domain
import Infrastructure
import Observation
import SwiftUI

enum SettingsSectionID: String, CaseIterable, Identifiable {
    case general
    case switcher
    case shortcuts
    case snap
    case titles
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .switcher: "Switcher"
        case .shortcuts: "Shortcuts"
        case .snap: "Snap"
        case .titles: "Titles"
        case .about: "About"
        }
    }

    var symbol: String {
        switch self {
        case .general: "slider.horizontal.3"
        case .switcher: "rectangle.stack"
        case .shortcuts: "keyboard"
        case .snap: "square.dashed"
        case .titles: "textformat"
        case .about: "info.circle"
        }
    }

    var shortcut: KeyEquivalent {
        switch self {
        case .general: "1"
        case .switcher: "2"
        case .shortcuts: "3"
        case .snap: "4"
        case .titles: "5"
        case .about: "6"
        }
    }

    var shortcutLabel: String {
        switch self {
        case .general: "1"
        case .switcher: "2"
        case .shortcuts: "3"
        case .snap: "4"
        case .titles: "5"
        case .about: "6"
        }
    }
}

@Observable
@MainActor
final class SettingsNavigation {
    var section: SettingsSectionID = .general
}

struct SettingsTabBar: View {
    @Bindable var navigation: SettingsNavigation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(SettingsSectionID.allCases.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Spacer(minLength: 8)
                }
                let selected = item == navigation.section
                Button {
                    navigation.section = item
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 11, weight: .semibold))
                        Text(item.title)
                            .font(.system(size: 12, weight: selected ? .semibold : .medium))
                    }
                    .foregroundStyle(selected ? Color.white : EcranChrome.secondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background {
                        if selected {
                            Capsule(style: .continuous)
                                .fill(EcranChrome.selectedFill)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .keyboardShortcut(item.shortcut, modifiers: .command)
                .help("\(item.title) (⌘\(item.shortcutLabel))")
            }
        }
        .padding(.horizontal, EcranChrome.pageInset)
        .frame(maxWidth: .infinity, minHeight: 52, maxHeight: 52)
        .background(Color(nsColor: EcranChrome.popoverNSColor))
        .overlay(alignment: .bottom) {
            Rectangle().fill(EcranChrome.hairline).frame(height: 1)
        }
        .preferredColorScheme(.dark)
    }
}

struct SettingsView: View {
    @Bindable var runtime: EcranRuntime
    @Bindable var navigation: SettingsNavigation

    var body: some View {
        Group {
            switch navigation.section {
            case .general: GeneralSettingsPane(runtime: runtime)
            case .switcher: SwitcherSettingsPane(runtime: runtime)
            case .shortcuts: ShortcutSettingsPane(runtime: runtime)
            case .snap: SnapSettingsPane(runtime: runtime)
            case .titles: TitleSettingsPane(runtime: runtime)
            case .about: AboutSettingsPane()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: EcranChrome.popoverNSColor))
        .preferredColorScheme(.dark)
        .frame(minWidth: 860, maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct GeneralSettingsPane: View {
    @Bindable var runtime: EcranRuntime

    var body: some View {
        SettingsPage {
            PageTitle(
                title: "General",
                subtitle: "Startup, permissions, and how window actions behave.",
                symbol: SettingsSectionID.general.symbol
            )

            SettingsColumns {
                SettingsGroup(title: "Startup", symbol: "power") {
                    SettingsCard {
                        VStack(spacing: 8) {
                            SettingsToggleRow(title: "Launch at login", isOn: launchAtLogin)
                            SettingsToggleRow(title: "Hide menu bar icon", isOn: hideIcon)
                            SettingsHairline()
                            VStack(alignment: .leading, spacing: 8) {
                                FieldLabel(title: "Language")
                                EcranSegmentBar(
                                    items: AppLanguage.allCases,
                                    selection: language,
                                    title: { $0.displayName }
                                )
                                SettingsCaption(text: "English is the app language. System follows your Mac for later translations.")
                            }
                        }
                    }
                }
            } right: {
                SettingsGroup(
                    title: "Permissions",
                    subtitle: "Needed to list, switch, move, and preview windows.",
                    symbol: "lock.shield"
                ) {
                    SettingsCard {
                        VStack(spacing: 10) {
                            PermissionRow(
                                title: "Accessibility",
                                granted: runtime.accessibilityTrusted,
                                required: true
                            ) {
                                AccessibilityAuthorization.request()
                                AccessibilityAuthorization.openSystemSettings()
                            }
                            SettingsHairline()
                            PermissionRow(
                                title: "Screen Recording",
                                granted: runtime.screenRecordingGranted,
                                required: false
                            ) {
                                AccessibilityAuthorization.requestScreenRecording()
                            }
                        }
                    }
                }
            }

            SettingsColumns {
                SettingsGroup(
                    title: "Placement",
                    subtitle: "What happens when you repeat a shortcut.",
                    symbol: "rectangle.split.2x1"
                ) {
                    SettingsCard {
                        VStack(spacing: 10) {
                            SettingsPickerRow(
                                title: "Repeat action",
                                selection: subsequentMode,
                                items: SubsequentExecutionMode.allCases,
                                label: { $0.displayName }
                            )
                            if showsCycleOptions {
                                VStack(alignment: .leading, spacing: 8) {
                                    FieldLabel(title: "Cycle sizes")
                                    LazyVGrid(
                                        columns: [GridItem(.adaptive(minimum: 72), spacing: 6)],
                                        alignment: .leading,
                                        spacing: 6
                                    ) {
                                        ForEach(CycleSize.allCases, id: \.self) { size in
                                            CycleSizeChip(size: size, isOn: cycleSize(size))
                                        }
                                    }
                                }
                                VStack(alignment: .leading, spacing: 8) {
                                    FieldLabel(title: "Corner cycle axis")
                                    EcranSegmentBar(
                                        items: CornerCycleAxis.allCases,
                                        selection: cornerAxis,
                                        title: { $0.displayName }
                                    )
                                }
                                SettingsToggleRow(
                                    title: "Cooperative corner resize",
                                    detail: "When you corner-tile, the neighboring window fills the rest of that band.",
                                    isOn: cooperative
                                )
                            }
                        }
                    }
                }
            } right: {
                SettingsGroup(
                    title: "Menu",
                    subtitle: "What the status menu lists next to placements.",
                    symbol: "menubar.rectangle"
                ) {
                    SettingsCard {
                        VStack(spacing: 8) {
                            SettingsToggleRow(title: "Show additional sizes in the menu", isOn: extraSizes)
                            SettingsToggleRow(title: "Halves keep the other axis", isOn: preserveAxis)
                        }
                    }
                }
            }

            SettingsColumns {
                SettingsGroup(title: "Window controls", symbol: "macwindow") {
                    SettingsCard {
                        VStack(spacing: 8) {
                            SettingsToggleRow(title: "Override the green zoom button", isOn: greenButton)
                            SettingsToggleRow(title: "Double-click title bar to maximize", isOn: titleBar)
                            SettingsToggleRow(
                                title: "Restore on a second title-bar click",
                                disabled: runtime.settings.doubleClickTitleBarAction != .maximize,
                                isOn: titleBarRestore
                            )
                        }
                    }
                }
            } right: {
                SettingsGroup(title: "Displays", symbol: "display.2") {
                    SettingsCard {
                        VStack(spacing: 8) {
                            SettingsToggleRow(title: "Treat displays as one canvas", isOn: combined)
                            SettingsToggleRow(title: "Use the cursor’s display", isOn: cursorScreen)
                            SettingsToggleRow(title: "Match last tile when moving displays", isOn: attemptMatch)
                            SettingsToggleRow(title: "Keep maximized windows maximized across displays", isOn: autoMax)
                            SettingsToggleRow(title: "Move the cursor with window actions", isOn: moveCursor)
                        }
                    }
                }
            }

            SettingsColumns {
                SettingsGroup(title: "Gaps", symbol: "arrow.up.left.and.arrow.down.right") {
                    SettingsCard {
                        VStack(spacing: 10) {
                            SettingsSliderRow(
                                title: "Inner gap",
                                value: gap,
                                range: 0...40,
                                display: "\(Int(runtime.settings.gapSize))"
                            )
                            SettingsToggleRow(title: "Skip gap at the top edge", isOn: skipTop)
                        }
                    }
                }
            } right: {
                SettingsGroup(title: "Screen edges", symbol: "rectangle.inset.filled") {
                    SettingsCard {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            SettingsNumericRow(title: "Top", value: edgeTop)
                            SettingsNumericRow(title: "Bottom", value: edgeBottom)
                            SettingsNumericRow(title: "Left", value: edgeLeft)
                            SettingsNumericRow(title: "Right", value: edgeRight)
                        }
                    }
                }
            }

            SettingsDisclosure(title: "Sizes", subtitle: "Almost maximize and specified dimensions") {
                SettingsCard {
                    VStack(spacing: 10) {
                        SettingsSliderRow(
                            title: "Almost width",
                            value: almostWidth,
                            range: 0.5...1,
                            step: 0.01,
                            display: "\(Int(runtime.settings.almostMaximizeWidth * 100))%"
                        )
                        SettingsSliderRow(
                            title: "Almost height",
                            value: almostHeight,
                            range: 0.5...1,
                            step: 0.01,
                            display: "\(Int(runtime.settings.almostMaximizeHeight * 100))%"
                        )
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            SettingsNumericRow(title: "Specified width", value: specifiedWidth)
                            SettingsNumericRow(title: "Specified height", value: specifiedHeight)
                        }
                    }
                }
            }

            SettingsDisclosure(title: "Todo sidebar", subtitle: "Reserve a strip for a chosen app") {
                SettingsCard {
                    VStack(spacing: 8) {
                        SettingsToggleRow(title: "Reserve a todo strip", isOn: todo)
                        VStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 8) {
                                FieldLabel(title: "Side")
                                EcranSegmentBar(
                                    items: AppSettings.TodoSide.allCases,
                                    selection: todoSide,
                                    title: { $0.displayName }
                                )
                            }
                            SettingsNumericRow(title: "Width", value: todoWidth)
                            SettingsPickerRow(
                                title: "App",
                                selection: todoApp,
                                items: [String?.none] + installedApps.map { Optional($0.0) },
                                label: { id in
                                    guard let id else { return "None" }
                                    return installedApps.first(where: { $0.0 == id })?.1 ?? id
                                }
                            )
                        }
                        .disabled(!runtime.settings.todoMode)
                        .opacity(runtime.settings.todoMode ? 1 : 0.55)
                    }
                }
            }

            SettingsDisclosure(
                title: "Ignored apps",
                subtitle: "Placement shortcuts and snap skip these apps. The switcher stays available."
            ) {
                SettingsCard {
                    if runtime.settings.ignoredBundleIDs.isEmpty {
                        SettingsCaption(text: "No ignored apps. Use Ignore Front App in the menu to add one.")
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(runtime.settings.ignoredBundleIDs.enumerated()), id: \.element) { index, bundleID in
                                if index > 0 { SettingsHairline() }
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(appName(for: bundleID))
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(.white)
                                        Text(bundleID)
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundStyle(EcranChrome.tertiaryText)
                                    }
                                    Spacer(minLength: 8)
                                    QuietButton(title: "Remove") {
                                        runtime.update { $0.ignoredBundleIDs.removeAll { $0 == bundleID } }
                                        runtime.persistAndReregisterHotkeys()
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                }
            }
        }
    }

    private var showsCycleOptions: Bool {
        switch runtime.settings.subsequentExecutionMode {
        case .resize, .acrossAndResize, .resizeAndCycleQuadrants: true
        default: false
        }
    }

    private var launchAtLogin: Binding<Bool> {
        Binding(get: { runtime.launchAtLoginEnabled }, set: { runtime.setLaunchAtLogin($0) })
    }

    private var hideIcon: Binding<Bool> {
        Binding(get: { runtime.settings.hideMenuBarIcon }, set: { value in runtime.update { $0.hideMenuBarIcon = value } })
    }

    private var language: Binding<AppLanguage> {
        Binding(get: { runtime.settings.language }, set: { value in
            runtime.update { $0.language = value }
            value.applyPreferredLanguages()
        })
    }

    private var subsequentMode: Binding<SubsequentExecutionMode> {
        Binding(get: { runtime.settings.subsequentExecutionMode }, set: { value in runtime.update { $0.subsequentExecutionMode = value } })
    }

    private var extraSizes: Binding<Bool> {
        Binding(get: { runtime.settings.showAdditionalSizesInMenu }, set: { value in runtime.update { $0.showAdditionalSizesInMenu = value } })
    }

    private var titleBar: Binding<Bool> {
        Binding(
            get: { runtime.settings.doubleClickTitleBarAction == .maximize },
            set: { value in runtime.update { $0.doubleClickTitleBarAction = value ? .maximize : nil } }
        )
    }

    private var titleBarRestore: Binding<Bool> {
        Binding(get: { runtime.settings.doubleClickTitleBarRestore }, set: { value in runtime.update { $0.doubleClickTitleBarRestore = value } })
    }

    private var preserveAxis: Binding<Bool> {
        Binding(get: { runtime.settings.halvesPreserveOtherAxisSize }, set: { value in runtime.update { $0.halvesPreserveOtherAxisSize = value } })
    }

    private var combined: Binding<Bool> {
        Binding(get: { runtime.settings.combinedDisplayMode }, set: { value in runtime.update { $0.combinedDisplayMode = value } })
    }

    private var cursorScreen: Binding<Bool> {
        Binding(get: { runtime.settings.useCursorScreenDetection }, set: { value in runtime.update { $0.useCursorScreenDetection = value } })
    }

    private var attemptMatch: Binding<Bool> {
        Binding(get: { runtime.settings.attemptMatchOnNextPrevDisplay }, set: { value in runtime.update { $0.attemptMatchOnNextPrevDisplay = value } })
    }

    private var autoMax: Binding<Bool> {
        Binding(get: { runtime.settings.autoMaximize }, set: { value in runtime.update { $0.autoMaximize = value } })
    }

    private var moveCursor: Binding<Bool> {
        Binding(get: { runtime.settings.moveCursorWithActions }, set: { value in runtime.update { $0.moveCursorWithActions = value } })
    }

    private var cornerAxis: Binding<CornerCycleAxis> {
        Binding(get: { runtime.settings.cornerCycleAxis }, set: { value in runtime.update { $0.cornerCycleAxis = value } })
    }

    private var cooperative: Binding<Bool> {
        Binding(get: { runtime.settings.cooperativeCornerResize }, set: { value in runtime.update { $0.cooperativeCornerResize = value } })
    }

    private func cycleSize(_ size: CycleSize) -> Binding<Bool> {
        Binding(
            get: { runtime.settings.selectedCycleSizes.contains(size) },
            set: { value in
                runtime.update { settings in
                    if value {
                        if !settings.selectedCycleSizes.contains(size) {
                            settings.selectedCycleSizes.append(size)
                        }
                    } else {
                        settings.selectedCycleSizes.removeAll { $0 == size }
                    }
                }
            }
        )
    }

    private var greenButton: Binding<Bool> {
        Binding(get: { runtime.settings.greenButtonOverride }, set: { value in runtime.update { $0.greenButtonOverride = value } })
    }

    private var gap: Binding<Double> {
        Binding(get: { runtime.settings.gapSize }, set: { value in runtime.update { $0.gapSize = value } })
    }

    private var skipTop: Binding<Bool> {
        Binding(get: { runtime.settings.skipGapTopEdge }, set: { value in runtime.update { $0.skipGapTopEdge = value } })
    }

    private var todo: Binding<Bool> {
        Binding(get: { runtime.settings.todoMode }, set: { value in runtime.update { $0.todoMode = value } })
    }

    private var todoSide: Binding<AppSettings.TodoSide> {
        Binding(get: { runtime.settings.todoSide }, set: { value in runtime.update { $0.todoSide = value } })
    }

    private var todoWidth: Binding<Double> {
        Binding(get: { runtime.settings.todoWidth }, set: { value in runtime.update { $0.todoWidth = value } })
    }

    private var todoApp: Binding<String?> {
        Binding(get: { runtime.settings.todoBundleID }, set: { value in runtime.update { $0.todoBundleID = value } })
    }

    private var edgeTop: Binding<Double> {
        Binding(get: { runtime.settings.screenEdgeGapTop }, set: { value in runtime.update { $0.screenEdgeGapTop = value } })
    }

    private var edgeBottom: Binding<Double> {
        Binding(get: { runtime.settings.screenEdgeGapBottom }, set: { value in runtime.update { $0.screenEdgeGapBottom = value } })
    }

    private var edgeLeft: Binding<Double> {
        Binding(get: { runtime.settings.screenEdgeGapLeft }, set: { value in runtime.update { $0.screenEdgeGapLeft = value } })
    }

    private var edgeRight: Binding<Double> {
        Binding(get: { runtime.settings.screenEdgeGapRight }, set: { value in runtime.update { $0.screenEdgeGapRight = value } })
    }

    private var almostWidth: Binding<Double> {
        Binding(get: { runtime.settings.almostMaximizeWidth }, set: { value in runtime.update { $0.almostMaximizeWidth = value } })
    }

    private var almostHeight: Binding<Double> {
        Binding(get: { runtime.settings.almostMaximizeHeight }, set: { value in runtime.update { $0.almostMaximizeHeight = value } })
    }

    private var specifiedWidth: Binding<Double> {
        Binding(get: { runtime.settings.specifiedWidth }, set: { value in runtime.update { $0.specifiedWidth = value } })
    }

    private var specifiedHeight: Binding<Double> {
        Binding(get: { runtime.settings.specifiedHeight }, set: { value in runtime.update { $0.specifiedHeight = value } })
    }

    private var installedApps: [(String, String)] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app in
                guard let id = app.bundleIdentifier else { return nil }
                return (id, app.localizedName ?? id)
            }
            .sorted { $0.1.localizedCaseInsensitiveCompare($1.1) == .orderedAscending }
    }

    private func appName(for bundleID: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
           let bundle = Bundle(url: url) {
            if let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, !name.isEmpty {
                return name
            }
            if let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String, !name.isEmpty {
                return name
            }
        }
        return installedApps.first(where: { $0.0 == bundleID })?.1 ?? bundleID
    }
}

struct SwitcherSettingsPane: View {
    @Bindable var runtime: EcranRuntime

    var body: some View {
        SettingsPage {
            PageTitle(
                title: "Switcher",
                subtitle: "Same-app windows and the app switcher overlay.",
                symbol: SettingsSectionID.switcher.symbol
            )

            SettingsColumns {
                SettingsGroup(title: "Hotkeys", symbol: "keyboard") {
                    SettingsCard {
                        VStack(spacing: 12) {
                            hotkeyRow(
                                title: "Same-app windows",
                                modifier: sameModifier,
                                trigger: sameTrigger
                            )
                            SettingsHairline()
                            SettingsToggleRow(title: "App switcher", isOn: appEnabled)
                            hotkeyRow(
                                title: "Apps",
                                modifier: appModifier,
                                trigger: appTrigger
                            )
                            .disabled(!runtime.settings.appSwitcherEnabled)
                            .opacity(runtime.settings.appSwitcherEnabled ? 1 : 0.55)
                        }
                    }
                }
            } right: {
                SettingsGroup(title: "Behavior", symbol: "switch.2") {
                    SettingsCard {
                        VStack(spacing: 8) {
                            SettingsToggleRow(title: "Show number keys", isOn: numbers)
                            SettingsToggleRow(title: "Follow the active window’s display", isOn: follow)
                            SettingsToggleRow(title: "Show windows from all Spaces", isOn: allSpaces)
                            SettingsToggleRow(title: "Stay visible across desktop slides", isOn: followDesktops)
                            SettingsToggleRow(title: "Double-tap to hold", isOn: hold)
                        }
                    }
                }
            }

            SettingsGroup(title: "Appearance", symbol: "paintpalette") {
                SettingsCard {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel(title: "Display style")
                            DisplayStylePicker(selection: style)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel(title: "Header")
                            EcranSegmentBar(
                                items: SwitcherHeaderStyle.allCases,
                                selection: header,
                                title: { $0.displayName }
                            )
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel(title: "Color")
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5),
                                spacing: 8
                            ) {
                                ForEach(SwitcherColorScheme.allCases, id: \.self) { scheme in
                                    ColorSchemeSwatch(
                                        scheme: scheme,
                                        isSelected: runtime.settings.colorScheme == scheme
                                    ) {
                                        runtime.update { $0.colorScheme = scheme }
                                    }
                                }
                            }
                        }
                        HStack(spacing: 10) {
                            SettingsSliderRow(
                                title: "Vertical position",
                                value: position,
                                range: 0.1...0.8,
                                step: 0.01,
                                display: String(format: "%.2f", runtime.settings.switcherVerticalPosition)
                            )
                            QuietButton(title: "Golden ratio", symbol: "circle.grid.cross") {
                                runtime.update { $0.switcherVerticalPosition = 0.39 }
                            }
                        }
                    }
                }
            }
        }
    }

    private func hotkeyRow(
        title: String,
        modifier: Binding<ModifierKey>,
        trigger: Binding<TriggerKey>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
            HStack(spacing: 8) {
                compactPicker(selection: modifier, items: ModifierKey.allCases, label: { $0.displayName })
                compactPicker(selection: trigger, items: TriggerKey.allCases, label: { KeyboardLayout.label(for: $0) })
                Spacer(minLength: 0)
            }
        }
    }

    private func compactPicker<Item: Hashable>(
        selection: Binding<Item>,
        items: [Item],
        label: @escaping (Item) -> String
    ) -> some View {
        Menu {
            ForEach(items, id: \.self) { item in
                Button(label(item)) { selection.wrappedValue = item }
            }
        } label: {
            HStack(spacing: 8) {
                Text(label(selection.wrappedValue))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
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

    private var sameModifier: Binding<ModifierKey> {
        Binding(get: { runtime.settings.modifierKey }, set: { value in
            runtime.update { $0.modifierKey = value }
            runtime.persistAndReregisterHotkeys()
        })
    }

    private var sameTrigger: Binding<TriggerKey> {
        Binding(get: { runtime.settings.triggerKey }, set: { value in
            runtime.update { $0.triggerKey = value }
            runtime.persistAndReregisterHotkeys()
        })
    }

    private var appEnabled: Binding<Bool> {
        Binding(get: { runtime.settings.appSwitcherEnabled }, set: { value in
            runtime.update { $0.appSwitcherEnabled = value }
            runtime.persistAndReregisterHotkeys()
        })
    }

    private var appModifier: Binding<ModifierKey> {
        Binding(get: { runtime.settings.appSwitcherModifierKey }, set: { value in
            runtime.update { $0.appSwitcherModifierKey = value }
            runtime.persistAndReregisterHotkeys()
        })
    }

    private var appTrigger: Binding<TriggerKey> {
        Binding(get: { runtime.settings.appSwitcherTriggerKey }, set: { value in
            runtime.update { $0.appSwitcherTriggerKey = value }
            runtime.persistAndReregisterHotkeys()
        })
    }

    private var numbers: Binding<Bool> {
        Binding(get: { runtime.settings.showNumberKeys }, set: { value in runtime.update { $0.showNumberKeys = value } })
    }

    private var follow: Binding<Bool> {
        Binding(get: { runtime.settings.switcherFollowActiveWindow }, set: { value in runtime.update { $0.switcherFollowActiveWindow = value } })
    }

    private var allSpaces: Binding<Bool> {
        Binding(get: { runtime.settings.showWindowsFromAllSpaces }, set: { value in runtime.update { $0.showWindowsFromAllSpaces = value } })
    }

    private var followDesktops: Binding<Bool> {
        Binding(get: { runtime.settings.followAcrossDesktops }, set: { value in runtime.update { $0.followAcrossDesktops = value } })
    }

    private var hold: Binding<Bool> {
        Binding(get: { runtime.settings.doubleTapToHold }, set: { value in runtime.update { $0.doubleTapToHold = value } })
    }

    private var style: Binding<WindowDisplayStyle> {
        Binding(get: { runtime.settings.windowDisplayStyle }, set: { value in runtime.update { $0.windowDisplayStyle = value } })
    }

    private var header: Binding<SwitcherHeaderStyle> {
        Binding(get: { runtime.settings.switcherHeaderStyle }, set: { value in runtime.update { $0.switcherHeaderStyle = value } })
    }

    private var position: Binding<Double> {
        Binding(get: { runtime.settings.switcherVerticalPosition }, set: { value in runtime.update { $0.switcherVerticalPosition = value } })
    }
}

struct ShortcutSettingsPane: View {
    @Bindable var runtime: EcranRuntime

    var body: some View {
        SettingsPage {
            PageTitle(
                title: "Shortcuts",
                subtitle: "Record a key combination for each placement. Recommended defaults match Rectangle.",
                symbol: SettingsSectionID.shortcuts.symbol
            )

            SettingsCard {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Presets")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                        SettingsCaption(text: "Load a starting set, then record any placement you want to change.")
                    }
                    Spacer(minLength: 12)
                    HStack(spacing: 8) {
                        QuietButton(title: "Recommended", symbol: "arrow.counterclockwise", prominence: .primary) {
                            runtime.update { $0.shortcuts = AppSettings.recommendedShortcuts }
                            runtime.persistAndReregisterHotkeys()
                        }
                        QuietButton(title: "Spectacle", symbol: "keyboard") {
                            runtime.update { $0.shortcuts = AppSettings.spectacleShortcuts }
                            runtime.persistAndReregisterHotkeys()
                        }
                        QuietButton(title: "Export", symbol: "square.and.arrow.up") { export() }
                        QuietButton(title: "Import", symbol: "square.and.arrow.down") { importConfig() }
                    }
                }
            }

            SettingsNotice(text: "⌃⌥ arrows for halves, ⌃⌥ U I J K for corners, and ⌃⌥ Return to maximize. Same-app switching defaults to ⌘`. App switching defaults to ⌘Tab.")

            ForEach(Array(stride(from: 0, to: groupedActions.count, by: 2)), id: \.self) { index in
                let left = groupedActions[index]
                if index + 1 < groupedActions.count {
                    let right = groupedActions[index + 1]
                    SettingsColumns {
                        shortcutGroup(left.0, left.1)
                    } right: {
                        shortcutGroup(right.0, right.1)
                    }
                } else {
                    shortcutGroup(left.0, left.1)
                }
            }

            if runtime.settings.showAdditionalSizesInMenu {
                SettingsGroup(title: "Additional sizes") {
                    SettingsCard(padding: 8) {
                        VStack(spacing: 0) {
                            ForEach(Array(WindowAction.additionalSizes.enumerated()), id: \.element.id) { index, action in
                                if index > 0 { SettingsHairline() }
                                ShortcutRecorderRow(action: action, runtime: runtime)
                            }
                        }
                    }
                }
            }
        }
    }

    private func shortcutGroup(_ category: WindowActionCategory, _ actions: [WindowAction]) -> some View {
        SettingsGroup(title: category.displayName) {
            SettingsCard(padding: 8) {
                VStack(spacing: 0) {
                    ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                        if index > 0 { SettingsHairline() }
                        ShortcutRecorderRow(action: action, runtime: runtime)
                    }
                }
            }
        }
    }

    private var groupedActions: [(WindowActionCategory, [WindowAction])] {
        var buckets: [WindowActionCategory: [WindowAction]] = [:]
        for action in WindowAction.menuOrder {
            buckets[action.category, default: []].append(action)
        }
        return WindowActionCategory.allCases.compactMap { category in
            if category == .todo, !runtime.settings.todoMode { return nil }
            guard let items = buckets[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    private func export() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "EcranConfig.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0-beta.1"
        if let data = try? ConfigImportExport.export(runtime.settings, version: version) {
            try? data.write(to: url)
        }
    }

    private func importConfig() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.urls.first, let data = try? Data(contentsOf: url) else { return }
        if let imported = try? ConfigImportExport.importSettings(from: data, into: runtime.settings, titlesOnly: false) {
            runtime.applyImportedSettings(imported)
        }
    }
}

struct SnapSettingsPane: View {
    @Bindable var runtime: EcranRuntime

    var body: some View {
        SettingsPage {
            PageTitle(
                title: "Snap",
                subtitle: "Drag a window to an edge or corner to place it.",
                symbol: SettingsSectionID.snap.symbol
            )

            SettingsColumns {
                SettingsGroup(title: "Drag snap", symbol: "hand.draw") {
                    SettingsCard {
                        VStack(spacing: 8) {
                            SettingsToggleRow(title: "Enable snapping", isOn: snap)
                            VStack(spacing: 8) {
                                SettingsToggleRow(title: "Restore size when dragging a snapped window", isOn: unsnap)
                                SettingsToggleRow(title: "Also ignore drag-snap in ignored apps", isOn: ignoreSnap)
                                SettingsHairline()
                                SettingsToggleRow(title: "Animate footprint", isOn: animate)
                                SettingsToggleRow(
                                    title: "Haptic feedback",
                                    detail: "Trackpad click when a snap zone lights up.",
                                    isOn: haptic
                                )
                                SettingsToggleRow(title: "Guard Mission Control drags", isOn: mission)
                                SettingsToggleRow(title: "Sixths on corner drags", isOn: sixths)
                            }
                            .disabled(!runtime.settings.windowSnapping)
                            .opacity(runtime.settings.windowSnapping ? 1 : 0.55)
                        }
                    }
                }
            } right: {
                SettingsGroup(title: "Zones", symbol: "rectangle.split.3x3") {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SnapZonePreview()
                            SettingsCaption(
                                text: "Left and right edges become halves, the top maximizes, corners become quarters, and the bottom edge offers thirds."
                            )
                        }
                    }
                }
            }
        }
    }

    private var snap: Binding<Bool> {
        Binding(get: { runtime.settings.windowSnapping }, set: { value in runtime.update { $0.windowSnapping = value } })
    }

    private var unsnap: Binding<Bool> {
        Binding(get: { runtime.settings.unsnapRestore }, set: { value in runtime.update { $0.unsnapRestore = value } })
    }

    private var ignoreSnap: Binding<Bool> {
        Binding(get: { runtime.settings.ignoreDragSnapToo }, set: { value in runtime.update { $0.ignoreDragSnapToo = value } })
    }

    private var animate: Binding<Bool> {
        Binding(get: { runtime.settings.animateFootprint }, set: { value in runtime.update { $0.animateFootprint = value } })
    }

    private var haptic: Binding<Bool> {
        Binding(get: { runtime.settings.hapticFeedbackOnSnap }, set: { value in
            runtime.update { $0.hapticFeedbackOnSnap = value }
            if value {
                HapticFeedback.alignment()
            }
        })
    }

    private var mission: Binding<Bool> {
        Binding(get: { runtime.settings.missionControlDragging }, set: { value in runtime.update { $0.missionControlDragging = value } })
    }

    private var sixths: Binding<Bool> {
        Binding(get: { runtime.settings.sixthsSnapArea }, set: { value in runtime.update { $0.sixthsSnapArea = value } })
    }
}

struct TitleSettingsPane: View {
    @Bindable var runtime: EcranRuntime
    @State private var bundleID = ""
    @State private var separator = " - "
    @State private var strategy = TitleExtractionStrategy.beforeFirstSeparator

    var body: some View {
        SettingsPage {
            PageTitle(
                title: "Window titles",
                subtitle: "How the switcher shortens project and document names.",
                symbol: SettingsSectionID.titles.symbol
            )

            SettingsColumns {
                SettingsGroup(title: "Default extraction", symbol: "text.alignleft") {
                    SettingsCard {
                        VStack(spacing: 10) {
                            SettingsPickerRow(
                                title: "Strategy",
                                selection: defaultStrategy,
                                items: TitleExtractionStrategy.allCases,
                                label: { $0.displayName }
                            )
                            HStack {
                                Text("Separator")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                                TextField(" - ", text: defaultSeparator)
                                    .ecranFieldChrome()
                                    .frame(width: 160)
                            }
                        }
                    }
                }
            } right: {
                SettingsGroup(title: "Backup", symbol: "square.and.arrow.up.on.square") {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SettingsCaption(text: "Export just the title rules, or bring them back on another Mac.")
                            HStack(spacing: 8) {
                                QuietButton(title: "Export titles", symbol: "square.and.arrow.up") { exportTitles() }
                                QuietButton(title: "Import titles", symbol: "square.and.arrow.down") { importTitles() }
                            }
                        }
                    }
                }
            }

            SettingsGroup(title: "Per-app overrides", symbol: "app.badge") {
                SettingsCard(padding: 8) {
                    VStack(spacing: 0) {
                        if runtime.settings.appTitleConfigs.isEmpty {
                            SettingsCaption(text: "No overrides yet. Choose a running app or type a bundle identifier.")
                                .padding(.horizontal, 6)
                                .padding(.vertical, 8)
                            SettingsHairline()
                        }
                        ForEach(runtime.settings.appTitleConfigs.sorted(by: { $0.key < $1.key }), id: \.key) { item in
                            HStack(spacing: 10) {
                                titleAppIcon(for: item.key)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(titleAppName(for: item.key))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.white)
                                    Text(item.key)
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundStyle(EcranChrome.tertiaryText)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 8)
                                StatusChip(text: item.value.strategy.displayName)
                                QuietButton(title: "Remove") {
                                    runtime.update { $0.appTitleConfigs.removeValue(forKey: item.key) }
                                }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 8)
                            SettingsHairline()
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            SettingsPickerRow(
                                title: "Installed app",
                                selection: $bundleID,
                                items: [""] + runningAppIDs,
                                label: { id in
                                    if id.isEmpty { return "Choose an app" }
                                    return runningApps.first(where: { $0.0 == id })?.1 ?? id
                                }
                            )
                            HStack(spacing: 8) {
                                TextField("Bundle identifier", text: $bundleID)
                                    .ecranFieldChrome()
                                Menu {
                                    ForEach(TitleExtractionStrategy.allCases, id: \.self) { item in
                                        Button(item.displayName) { strategy = item }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(strategy.displayName)
                                            .font(.system(size: 12, weight: .medium))
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(EcranChrome.tertiaryText)
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .frame(minHeight: 30)
                                    .background(
                                        EcranChrome.fieldFill,
                                        in: RoundedRectangle(cornerRadius: EcranChrome.fieldRadius, style: .continuous)
                                    )
                                }
                                .menuStyle(.borderlessButton)
                                .menuIndicator(.hidden)
                                TextField("Separator", text: $separator)
                                    .ecranFieldChrome()
                                    .frame(width: 80)
                                QuietButton(title: "Add", prominence: .primary) {
                                    guard !bundleID.isEmpty else { return }
                                    runtime.update {
                                        $0.appTitleConfigs[bundleID] = AppTitleConfig(strategy: strategy, customSeparator: separator)
                                    }
                                    bundleID = ""
                                }
                            }
                        }
                        .padding(6)
                        .padding(.top, 6)
                    }
                }
            }
        }
    }

    private var runningApps: [(String, String)] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> (String, String)? in
                guard let id = app.bundleIdentifier else { return nil }
                return (id, app.localizedName ?? id)
            }
            .sorted { $0.1 < $1.1 }
    }

    private var runningAppIDs: [String] { runningApps.map(\.0) }

    private func titleAppName(for bundleID: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
           let bundle = Bundle(url: url) {
            if let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, !name.isEmpty {
                return name
            }
            if let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String, !name.isEmpty {
                return name
            }
        }
        return runningApps.first(where: { $0.0 == bundleID })?.1 ?? bundleID
    }

    @ViewBuilder
    private func titleAppIcon(for bundleID: String) -> some View {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .interpolation(.high)
                .frame(width: 20, height: 20)
        } else {
            SettingsGlyph(symbol: "app", size: 24)
        }
    }

    private var defaultStrategy: Binding<TitleExtractionStrategy> {
        Binding(get: { runtime.settings.defaultTitleStrategy }, set: { value in runtime.update { $0.defaultTitleStrategy = value } })
    }

    private var defaultSeparator: Binding<String> {
        Binding(get: { runtime.settings.defaultCustomSeparator }, set: { value in runtime.update { $0.defaultCustomSeparator = value } })
    }

    private func exportTitles() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "EcranTitles.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let data = try? ConfigImportExport.exportTitles(runtime.settings) {
            try? data.write(to: url)
        }
    }

    private func importTitles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.urls.first, let data = try? Data(contentsOf: url) else { return }
        if let imported = try? ConfigImportExport.importSettings(from: data, into: runtime.settings, titlesOnly: true) {
            runtime.applyImportedSettings(imported)
        }
    }
}

struct ShortcutRecorderRow: View {
    let action: WindowAction
    @Bindable var runtime: EcranRuntime
    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: PlacementIcon.image(for: action))
                .resizable()
                .interpolation(.high)
                .frame(width: 18, height: 12)
                .opacity(0.9)
            Text(action.displayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button(recording ? "Type a shortcut…" : chordLabel) {
                startRecording()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(recording ? Color.white : EcranChrome.secondaryText)
            .padding(.horizontal, 10)
            .frame(minHeight: 28)
            .background(
                recording ? Color.white.opacity(0.12) : EcranChrome.fieldFill,
                in: RoundedRectangle(cornerRadius: 7, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(recording ? EcranChrome.selectionBorder : EcranChrome.controlBorder, lineWidth: 1)
            }
            .fixedSize()
            .layoutPriority(1)
            if runtime.settings.shortcuts[action] != nil {
                QuietButton(title: "Clear") {
                    runtime.update { $0.shortcuts.removeValue(forKey: action) }
                    runtime.persistAndReregisterHotkeys()
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .onDisappear {
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
            recording = false
        }
    }

    private var chordLabel: String {
        ShortcutRecorderRow.label(for: runtime.settings.shortcuts[action])
    }

    private func startRecording() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
            if event.keyCode == 53 {
                recording = false
                return nil
            }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
            runtime.update {
                $0.shortcuts[action] = KeyChord(keyCode: event.keyCode, modifierFlags: flags)
            }
            runtime.persistAndReregisterHotkeys()
            recording = false
            return nil
        }
    }

    static func label(for chord: KeyChord?) -> String {
        guard let chord else { return "Click to record" }
        return KeyboardLayout.displayLabel(for: chord)
    }
}

struct AboutSettingsPane: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0-beta.1"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        SettingsPage(alignment: .top) {
            VStack(spacing: 10) {
                EcranAppMark()
                    .frame(width: 64, height: 64)
                Text(AppIdentity.current.displayName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                Text(
                    AppIdentity.current.isDevelopment
                        ? "Development build — isolated from the shipped app"
                        : "Switch, snap, and place every window on your Mac"
                )
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(EcranChrome.secondaryText)
                .multilineTextAlignment(.center)
                Text("Version \(version) (\(build))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(EcranChrome.tertiaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)

            HStack(alignment: .top, spacing: 16) {
                SettingsFeatureTile(
                    symbol: "rectangle.stack",
                    title: "Switcher",
                    detail: "Same-app windows and a Command-Tab list that stays on this Mac."
                )
                SettingsFeatureTile(
                    symbol: "square.dashed",
                    title: "Snap",
                    detail: "Drag to an edge or corner to place a window without a shortcut."
                )
                SettingsFeatureTile(
                    symbol: "rectangle.split.2x1",
                    title: "Place",
                    detail: "Keyboard placements, cycles, and arrange actions from the menu."
                )
            }

            Text("A list-only window switcher and a keyboard-and-snap window manager in one menu-bar app. Nothing leaves this machine.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(EcranChrome.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                QuietButton(title: "GitHub", symbol: "chevron.left.forwardslash.chevron.right") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/basique-industrie/ecran")!)
                }
                QuietButton(title: "Open logs", symbol: "folder") {
                    AppLog.openLogsDirectory()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
