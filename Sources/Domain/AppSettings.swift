import Foundation

public struct AppSettings: Hashable, Codable, Sendable {
    public var language: AppLanguage
    public var launchAtLogin: Bool
    public var hideMenuBarIcon: Bool

    public var modifierKey: ModifierKey
    public var triggerKey: TriggerKey
    public var appSwitcherEnabled: Bool
    public var appSwitcherModifierKey: ModifierKey
    public var appSwitcherTriggerKey: TriggerKey
    public var showNumberKeys: Bool
    public var switcherFollowActiveWindow: Bool
    public var showWindowsFromAllSpaces: Bool
    public var followAcrossDesktops: Bool
    public var doubleTapToHold: Bool
    public var windowDisplayStyle: WindowDisplayStyle
    public var switcherVerticalPosition: Double
    public var switcherHeaderStyle: SwitcherHeaderStyle
    public var colorScheme: SwitcherColorScheme
    public var defaultTitleStrategy: TitleExtractionStrategy
    public var defaultCustomSeparator: String
    public var appTitleConfigs: [String: AppTitleConfig]

    public var subsequentExecutionMode: SubsequentExecutionMode
    public var selectedCycleSizes: [CycleSize]
    public var cornerCycleAxis: CornerCycleAxis
    public var cooperativeCornerResize: Bool
    public var gapSize: Double
    public var skipGapTopEdge: Bool
    public var screenEdgeGapTop: Double
    public var screenEdgeGapBottom: Double
    public var screenEdgeGapLeft: Double
    public var screenEdgeGapRight: Double
    public var screenEdgeGapTopNotch: Double
    public var screenEdgeGapsOnMainScreenOnly: Bool
    public var almostMaximizeWidth: Double
    public var almostMaximizeHeight: Double
    public var minimumWindowWidth: Double
    public var minimumWindowHeight: Double
    public var sizeOffset: Double
    public var widthStepSize: Double
    public var specifiedWidth: Double
    public var specifiedHeight: Double
    public var cascadeDelta: Double
    public var traverseSingleScreen: Bool
    public var useCursorScreenDetection: Bool
    public var attemptMatchOnNextPrevDisplay: Bool
    public var autoMaximize: Bool
    public var combinedDisplayMode: Bool
    public var screensOrderedBy: ScreenOrder
    public var resizeOnDirectionalMove: Bool
    public var centeredDirectionalMove: Bool
    public var halvesPreserveOtherAxisSize: Bool
    public var moveCursorAcrossDisplays: Bool
    public var moveCursorWithActions: Bool
    public var centerHalfCycles: Bool
    public var applyGapsToMaximize: Bool
    public var applyGapsToMaximizeHeight: Bool

    public var windowSnapping: Bool
    public var unsnapRestore: Bool
    public var animateFootprint: Bool
    public var hapticFeedbackOnSnap: Bool
    public var missionControlDragging: Bool
    public var sixthsSnapArea: Bool
    public var snapMargins: SnapMargins
    public var snapAreas: SnapAreaMap
    public var footprintAlpha: Double

    public var ignoredBundleIDs: [String]
    public var ignoreDragSnapToo: Bool
    public var showAdditionalSizesInMenu: Bool
    public var doubleClickTitleBarAction: WindowAction?
    public var doubleClickTitleBarRestore: Bool
    public var greenButtonOverride: Bool
    public var todoMode: Bool
    public var todoSide: TodoSide
    public var todoWidth: Double
    public var todoIsFraction: Bool
    public var todoBundleID: String?
    public var shortcuts: [WindowAction: KeyChord]

    public enum TodoSide: String, CaseIterable, Codable, Sendable {
        case left
        case right

        public var displayName: String {
            switch self {
            case .left: "Left"
            case .right: "Right"
            }
        }
    }

    public static let `default` = AppSettings()

    public init() {
        language = .system
        launchAtLogin = false
        hideMenuBarIcon = false
        modifierKey = .command
        triggerKey = .grave
        appSwitcherEnabled = true
        appSwitcherModifierKey = .command
        appSwitcherTriggerKey = .tab
        showNumberKeys = true
        switcherFollowActiveWindow = true
        showWindowsFromAllSpaces = true
        followAcrossDesktops = true
        doubleTapToHold = false
        windowDisplayStyle = .initials
        switcherVerticalPosition = 0.39
        switcherHeaderStyle = .default
        colorScheme = .system
        defaultTitleStrategy = .beforeFirstSeparator
        defaultCustomSeparator = " - "
        appTitleConfigs = TitleExtractor.builtInAppConfigs
        subsequentExecutionMode = .acrossMonitor
        selectedCycleSizes = CycleSize.defaultSelection
        cornerCycleAxis = .horizontal
        cooperativeCornerResize = false
        gapSize = 0
        skipGapTopEdge = false
        screenEdgeGapTop = 0
        screenEdgeGapBottom = 0
        screenEdgeGapLeft = 0
        screenEdgeGapRight = 0
        screenEdgeGapTopNotch = 0
        screenEdgeGapsOnMainScreenOnly = false
        almostMaximizeWidth = 0.9
        almostMaximizeHeight = 0.9
        minimumWindowWidth = 0.25
        minimumWindowHeight = 0.25
        sizeOffset = 30
        widthStepSize = 30
        specifiedWidth = 1680
        specifiedHeight = 1050
        cascadeDelta = 30
        traverseSingleScreen = false
        useCursorScreenDetection = false
        attemptMatchOnNextPrevDisplay = false
        autoMaximize = true
        combinedDisplayMode = false
        screensOrderedBy = .yThenMinX
        resizeOnDirectionalMove = false
        centeredDirectionalMove = true
        halvesPreserveOtherAxisSize = false
        moveCursorAcrossDisplays = false
        moveCursorWithActions = false
        centerHalfCycles = false
        applyGapsToMaximize = true
        applyGapsToMaximizeHeight = true
        windowSnapping = true
        unsnapRestore = true
        animateFootprint = true
        hapticFeedbackOnSnap = false
        missionControlDragging = true
        sixthsSnapArea = false
        snapMargins = SnapMargins()
        snapAreas = SnapAreaMap()
        footprintAlpha = 0.3
        ignoredBundleIDs = []
        ignoreDragSnapToo = true
        showAdditionalSizesInMenu = false
        doubleClickTitleBarAction = nil
        doubleClickTitleBarRestore = true
        greenButtonOverride = false
        todoMode = false
        todoSide = .right
        todoWidth = 400
        todoIsFraction = false
        todoBundleID = nil
        shortcuts = Self.recommendedShortcuts
    }

    public var clampedVerticalPosition: Double {
        min(0.8, max(0.1, switcherVerticalPosition))
    }

    public func isIgnored(_ bundleID: String) -> Bool {
        ignoredBundleIDs.contains(bundleID)
    }

    public mutating func toggleIgnored(_ bundleID: String) {
        if let index = ignoredBundleIDs.firstIndex(of: bundleID) {
            ignoredBundleIDs.remove(at: index)
        } else {
            ignoredBundleIDs.append(bundleID)
        }
    }

    public static let recommendedShortcuts: [WindowAction: KeyChord] = {
        var map: [WindowAction: KeyChord] = [:]
        map[.leftHalf] = .optionControl(123)
        map[.rightHalf] = .optionControl(124)
        map[.topHalf] = .optionControl(126)
        map[.bottomHalf] = .optionControl(125)
        map[.topLeft] = .optionControl(32)
        map[.topRight] = .optionControl(34)
        map[.bottomLeft] = .optionControl(38)
        map[.bottomRight] = .optionControl(40)
        map[.maximize] = .optionControl(36)
        map[.larger] = .optionControl(24)
        map[.smaller] = .optionControl(27)
        map[.firstThird] = .optionControl(2)
        map[.centerThird] = .optionControl(3)
        map[.lastThird] = .optionControl(5)
        map[.firstTwoThirds] = .optionControl(14)
        map[.lastTwoThirds] = .optionControl(17)
        map[.centerTwoThirds] = .optionControl(15)
        map[.center] = .optionControl(8)
        map[.restore] = .optionControl(51)
        map[.previousDisplay] = .optionControlCommand(123)
        map[.nextDisplay] = .optionControlCommand(124)
        return map
    }()

    public static let spectacleShortcuts: [WindowAction: KeyChord] = {
        var map: [WindowAction: KeyChord] = [:]
        map[.leftHalf] = .optionControl(123)
        map[.rightHalf] = .optionControl(124)
        map[.topHalf] = .optionControl(126)
        map[.bottomHalf] = .optionControl(125)
        map[.maximize] = .optionControl(3)
        map[.maximizeHeight] = .optionControlShift(126)
        map[.previousDisplay] = .optionControlCommand(123)
        map[.nextDisplay] = .optionControlCommand(124)
        map[.larger] = .optionControlShift(124)
        map[.smaller] = .optionControlShift(123)
        map[.center] = .optionControl(8)
        map[.restore] = .optionControl(51)
        return map
    }()

    enum CodingKeys: String, CodingKey {
        case language, launchAtLogin, hideMenuBarIcon
        case modifierKey, triggerKey, appSwitcherEnabled, appSwitcherModifierKey, appSwitcherTriggerKey
        case ct2Enabled, ct2ModifierKey, ct2TriggerKey
        case showNumberKeys, switcherFollowActiveWindow, showWindowsFromAllSpaces
        case followAcrossDesktops, doubleTapToHold, windowDisplayStyle, showWindowPreviews
        case switcherVerticalPosition, switcherHeaderStyle, colorScheme
        case defaultTitleStrategy, defaultCustomSeparator, appTitleConfigs
        case subsequentExecutionMode, selectedCycleSizes, cornerCycleAxis, cooperativeCornerResize
        case gapSize, skipGapTopEdge, screenEdgeGapTop, screenEdgeGapBottom, screenEdgeGapLeft
        case screenEdgeGapRight, screenEdgeGapTopNotch, screenEdgeGapsOnMainScreenOnly
        case almostMaximizeWidth, almostMaximizeHeight, minimumWindowWidth, minimumWindowHeight
        case sizeOffset, widthStepSize, specifiedWidth, specifiedHeight, cascadeDelta
        case traverseSingleScreen, useCursorScreenDetection, attemptMatchOnNextPrevDisplay
        case autoMaximize, combinedDisplayMode, screensOrderedBy, resizeOnDirectionalMove
        case centeredDirectionalMove, halvesPreserveOtherAxisSize, moveCursorAcrossDisplays
        case moveCursorWithActions, centerHalfCycles, applyGapsToMaximize, applyGapsToMaximizeHeight
        case windowSnapping, unsnapRestore, animateFootprint, hapticFeedbackOnSnap
        case missionControlDragging, sixthsSnapArea, snapMargins, snapAreas, footprintAlpha
        case ignoredBundleIDs, ignoreDragSnapToo, showAdditionalSizesInMenu, doubleClickTitleBarAction
        case doubleClickTitleBarRestore, greenButtonOverride, todoMode, todoSide, todoWidth
        case todoIsFraction, todoBundleID, shortcuts
    }

    public init(from decoder: Decoder) throws {
        let defaults = AppSettings()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? defaults.language
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? defaults.launchAtLogin
        hideMenuBarIcon = try container.decodeIfPresent(Bool.self, forKey: .hideMenuBarIcon) ?? defaults.hideMenuBarIcon
        modifierKey = try container.decodeIfPresent(ModifierKey.self, forKey: .modifierKey) ?? defaults.modifierKey
        triggerKey = try container.decodeIfPresent(TriggerKey.self, forKey: .triggerKey) ?? defaults.triggerKey
        appSwitcherEnabled = try container.decodeIfPresent(Bool.self, forKey: .appSwitcherEnabled)
            ?? container.decodeIfPresent(Bool.self, forKey: .ct2Enabled)
            ?? defaults.appSwitcherEnabled
        appSwitcherModifierKey = try container.decodeIfPresent(ModifierKey.self, forKey: .appSwitcherModifierKey)
            ?? container.decodeIfPresent(ModifierKey.self, forKey: .ct2ModifierKey)
            ?? defaults.appSwitcherModifierKey
        appSwitcherTriggerKey = try container.decodeIfPresent(TriggerKey.self, forKey: .appSwitcherTriggerKey)
            ?? container.decodeIfPresent(TriggerKey.self, forKey: .ct2TriggerKey)
            ?? defaults.appSwitcherTriggerKey
        showNumberKeys = try container.decodeIfPresent(Bool.self, forKey: .showNumberKeys) ?? defaults.showNumberKeys
        switcherFollowActiveWindow = try container.decodeIfPresent(Bool.self, forKey: .switcherFollowActiveWindow)
            ?? defaults.switcherFollowActiveWindow
        showWindowsFromAllSpaces = try container.decodeIfPresent(Bool.self, forKey: .showWindowsFromAllSpaces)
            ?? defaults.showWindowsFromAllSpaces
        followAcrossDesktops = try container.decodeIfPresent(Bool.self, forKey: .followAcrossDesktops)
            ?? defaults.followAcrossDesktops
        doubleTapToHold = try container.decodeIfPresent(Bool.self, forKey: .doubleTapToHold) ?? defaults.doubleTapToHold
        if let style = try container.decodeIfPresent(WindowDisplayStyle.self, forKey: .windowDisplayStyle) {
            windowDisplayStyle = style
        } else if try container.decodeIfPresent(Bool.self, forKey: .showWindowPreviews) == true {
            windowDisplayStyle = .preview
        } else {
            windowDisplayStyle = defaults.windowDisplayStyle
        }
        switcherVerticalPosition = try container.decodeIfPresent(Double.self, forKey: .switcherVerticalPosition)
            ?? defaults.switcherVerticalPosition
        switcherHeaderStyle = try container.decodeIfPresent(SwitcherHeaderStyle.self, forKey: .switcherHeaderStyle)
            ?? defaults.switcherHeaderStyle
        colorScheme = try container.decodeIfPresent(SwitcherColorScheme.self, forKey: .colorScheme) ?? defaults.colorScheme
        defaultTitleStrategy = try container.decodeIfPresent(TitleExtractionStrategy.self, forKey: .defaultTitleStrategy)
            ?? defaults.defaultTitleStrategy
        defaultCustomSeparator = try container.decodeIfPresent(String.self, forKey: .defaultCustomSeparator)
            ?? defaults.defaultCustomSeparator
        appTitleConfigs = try container.decodeIfPresent([String: AppTitleConfig].self, forKey: .appTitleConfigs)
            ?? defaults.appTitleConfigs
        subsequentExecutionMode = try container.decodeIfPresent(SubsequentExecutionMode.self, forKey: .subsequentExecutionMode)
            ?? defaults.subsequentExecutionMode
        selectedCycleSizes = try container.decodeIfPresent([CycleSize].self, forKey: .selectedCycleSizes)
            ?? defaults.selectedCycleSizes
        cornerCycleAxis = try container.decodeIfPresent(CornerCycleAxis.self, forKey: .cornerCycleAxis)
            ?? defaults.cornerCycleAxis
        cooperativeCornerResize = try container.decodeIfPresent(Bool.self, forKey: .cooperativeCornerResize)
            ?? defaults.cooperativeCornerResize
        gapSize = try container.decodeIfPresent(Double.self, forKey: .gapSize) ?? defaults.gapSize
        skipGapTopEdge = try container.decodeIfPresent(Bool.self, forKey: .skipGapTopEdge) ?? defaults.skipGapTopEdge
        screenEdgeGapTop = try container.decodeIfPresent(Double.self, forKey: .screenEdgeGapTop) ?? defaults.screenEdgeGapTop
        screenEdgeGapBottom = try container.decodeIfPresent(Double.self, forKey: .screenEdgeGapBottom)
            ?? defaults.screenEdgeGapBottom
        screenEdgeGapLeft = try container.decodeIfPresent(Double.self, forKey: .screenEdgeGapLeft) ?? defaults.screenEdgeGapLeft
        screenEdgeGapRight = try container.decodeIfPresent(Double.self, forKey: .screenEdgeGapRight)
            ?? defaults.screenEdgeGapRight
        screenEdgeGapTopNotch = try container.decodeIfPresent(Double.self, forKey: .screenEdgeGapTopNotch)
            ?? defaults.screenEdgeGapTopNotch
        screenEdgeGapsOnMainScreenOnly = try container.decodeIfPresent(Bool.self, forKey: .screenEdgeGapsOnMainScreenOnly)
            ?? defaults.screenEdgeGapsOnMainScreenOnly
        almostMaximizeWidth = try container.decodeIfPresent(Double.self, forKey: .almostMaximizeWidth)
            ?? defaults.almostMaximizeWidth
        almostMaximizeHeight = try container.decodeIfPresent(Double.self, forKey: .almostMaximizeHeight)
            ?? defaults.almostMaximizeHeight
        minimumWindowWidth = try container.decodeIfPresent(Double.self, forKey: .minimumWindowWidth)
            ?? defaults.minimumWindowWidth
        minimumWindowHeight = try container.decodeIfPresent(Double.self, forKey: .minimumWindowHeight)
            ?? defaults.minimumWindowHeight
        sizeOffset = try container.decodeIfPresent(Double.self, forKey: .sizeOffset) ?? defaults.sizeOffset
        widthStepSize = try container.decodeIfPresent(Double.self, forKey: .widthStepSize) ?? defaults.widthStepSize
        specifiedWidth = try container.decodeIfPresent(Double.self, forKey: .specifiedWidth) ?? defaults.specifiedWidth
        specifiedHeight = try container.decodeIfPresent(Double.self, forKey: .specifiedHeight) ?? defaults.specifiedHeight
        cascadeDelta = try container.decodeIfPresent(Double.self, forKey: .cascadeDelta) ?? defaults.cascadeDelta
        traverseSingleScreen = try container.decodeIfPresent(Bool.self, forKey: .traverseSingleScreen)
            ?? defaults.traverseSingleScreen
        useCursorScreenDetection = try container.decodeIfPresent(Bool.self, forKey: .useCursorScreenDetection)
            ?? defaults.useCursorScreenDetection
        attemptMatchOnNextPrevDisplay = try container.decodeIfPresent(Bool.self, forKey: .attemptMatchOnNextPrevDisplay)
            ?? defaults.attemptMatchOnNextPrevDisplay
        autoMaximize = try container.decodeIfPresent(Bool.self, forKey: .autoMaximize) ?? defaults.autoMaximize
        combinedDisplayMode = try container.decodeIfPresent(Bool.self, forKey: .combinedDisplayMode)
            ?? defaults.combinedDisplayMode
        screensOrderedBy = try container.decodeIfPresent(ScreenOrder.self, forKey: .screensOrderedBy)
            ?? defaults.screensOrderedBy
        resizeOnDirectionalMove = try container.decodeIfPresent(Bool.self, forKey: .resizeOnDirectionalMove)
            ?? defaults.resizeOnDirectionalMove
        centeredDirectionalMove = try container.decodeIfPresent(Bool.self, forKey: .centeredDirectionalMove)
            ?? defaults.centeredDirectionalMove
        halvesPreserveOtherAxisSize = try container.decodeIfPresent(Bool.self, forKey: .halvesPreserveOtherAxisSize)
            ?? defaults.halvesPreserveOtherAxisSize
        moveCursorAcrossDisplays = try container.decodeIfPresent(Bool.self, forKey: .moveCursorAcrossDisplays)
            ?? defaults.moveCursorAcrossDisplays
        moveCursorWithActions = try container.decodeIfPresent(Bool.self, forKey: .moveCursorWithActions)
            ?? defaults.moveCursorWithActions
        centerHalfCycles = try container.decodeIfPresent(Bool.self, forKey: .centerHalfCycles) ?? defaults.centerHalfCycles
        applyGapsToMaximize = try container.decodeIfPresent(Bool.self, forKey: .applyGapsToMaximize)
            ?? defaults.applyGapsToMaximize
        applyGapsToMaximizeHeight = try container.decodeIfPresent(Bool.self, forKey: .applyGapsToMaximizeHeight)
            ?? defaults.applyGapsToMaximizeHeight
        windowSnapping = try container.decodeIfPresent(Bool.self, forKey: .windowSnapping) ?? defaults.windowSnapping
        unsnapRestore = try container.decodeIfPresent(Bool.self, forKey: .unsnapRestore) ?? defaults.unsnapRestore
        animateFootprint = try container.decodeIfPresent(Bool.self, forKey: .animateFootprint) ?? defaults.animateFootprint
        hapticFeedbackOnSnap = try container.decodeIfPresent(Bool.self, forKey: .hapticFeedbackOnSnap)
            ?? defaults.hapticFeedbackOnSnap
        missionControlDragging = try container.decodeIfPresent(Bool.self, forKey: .missionControlDragging)
            ?? defaults.missionControlDragging
        sixthsSnapArea = try container.decodeIfPresent(Bool.self, forKey: .sixthsSnapArea) ?? defaults.sixthsSnapArea
        snapMargins = try container.decodeIfPresent(SnapMargins.self, forKey: .snapMargins) ?? defaults.snapMargins
        snapAreas = try container.decodeIfPresent(SnapAreaMap.self, forKey: .snapAreas) ?? defaults.snapAreas
        footprintAlpha = try container.decodeIfPresent(Double.self, forKey: .footprintAlpha) ?? defaults.footprintAlpha
        ignoredBundleIDs = try container.decodeIfPresent([String].self, forKey: .ignoredBundleIDs)
            ?? defaults.ignoredBundleIDs
        ignoreDragSnapToo = try container.decodeIfPresent(Bool.self, forKey: .ignoreDragSnapToo)
            ?? defaults.ignoreDragSnapToo
        showAdditionalSizesInMenu = try container.decodeIfPresent(Bool.self, forKey: .showAdditionalSizesInMenu)
            ?? defaults.showAdditionalSizesInMenu
        doubleClickTitleBarAction = try container.decodeIfPresent(WindowAction.self, forKey: .doubleClickTitleBarAction)
        doubleClickTitleBarRestore = try container.decodeIfPresent(Bool.self, forKey: .doubleClickTitleBarRestore)
            ?? defaults.doubleClickTitleBarRestore
        greenButtonOverride = try container.decodeIfPresent(Bool.self, forKey: .greenButtonOverride)
            ?? defaults.greenButtonOverride
        todoMode = try container.decodeIfPresent(Bool.self, forKey: .todoMode) ?? defaults.todoMode
        todoSide = try container.decodeIfPresent(TodoSide.self, forKey: .todoSide) ?? defaults.todoSide
        todoWidth = try container.decodeIfPresent(Double.self, forKey: .todoWidth) ?? defaults.todoWidth
        todoIsFraction = try container.decodeIfPresent(Bool.self, forKey: .todoIsFraction) ?? defaults.todoIsFraction
        todoBundleID = try container.decodeIfPresent(String.self, forKey: .todoBundleID)
        shortcuts = try container.decodeIfPresent([WindowAction: KeyChord].self, forKey: .shortcuts)
            ?? defaults.shortcuts
        switcherVerticalPosition = min(0.8, max(0.1, switcherVerticalPosition))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(language, forKey: .language)
        try container.encode(launchAtLogin, forKey: .launchAtLogin)
        try container.encode(hideMenuBarIcon, forKey: .hideMenuBarIcon)
        try container.encode(modifierKey, forKey: .modifierKey)
        try container.encode(triggerKey, forKey: .triggerKey)
        try container.encode(appSwitcherEnabled, forKey: .appSwitcherEnabled)
        try container.encode(appSwitcherModifierKey, forKey: .appSwitcherModifierKey)
        try container.encode(appSwitcherTriggerKey, forKey: .appSwitcherTriggerKey)
        try container.encode(showNumberKeys, forKey: .showNumberKeys)
        try container.encode(switcherFollowActiveWindow, forKey: .switcherFollowActiveWindow)
        try container.encode(showWindowsFromAllSpaces, forKey: .showWindowsFromAllSpaces)
        try container.encode(followAcrossDesktops, forKey: .followAcrossDesktops)
        try container.encode(doubleTapToHold, forKey: .doubleTapToHold)
        try container.encode(windowDisplayStyle, forKey: .windowDisplayStyle)
        try container.encode(switcherVerticalPosition, forKey: .switcherVerticalPosition)
        try container.encode(switcherHeaderStyle, forKey: .switcherHeaderStyle)
        try container.encode(colorScheme, forKey: .colorScheme)
        try container.encode(defaultTitleStrategy, forKey: .defaultTitleStrategy)
        try container.encode(defaultCustomSeparator, forKey: .defaultCustomSeparator)
        try container.encode(appTitleConfigs, forKey: .appTitleConfigs)
        try container.encode(subsequentExecutionMode, forKey: .subsequentExecutionMode)
        try container.encode(selectedCycleSizes, forKey: .selectedCycleSizes)
        try container.encode(cornerCycleAxis, forKey: .cornerCycleAxis)
        try container.encode(cooperativeCornerResize, forKey: .cooperativeCornerResize)
        try container.encode(gapSize, forKey: .gapSize)
        try container.encode(skipGapTopEdge, forKey: .skipGapTopEdge)
        try container.encode(screenEdgeGapTop, forKey: .screenEdgeGapTop)
        try container.encode(screenEdgeGapBottom, forKey: .screenEdgeGapBottom)
        try container.encode(screenEdgeGapLeft, forKey: .screenEdgeGapLeft)
        try container.encode(screenEdgeGapRight, forKey: .screenEdgeGapRight)
        try container.encode(screenEdgeGapTopNotch, forKey: .screenEdgeGapTopNotch)
        try container.encode(screenEdgeGapsOnMainScreenOnly, forKey: .screenEdgeGapsOnMainScreenOnly)
        try container.encode(almostMaximizeWidth, forKey: .almostMaximizeWidth)
        try container.encode(almostMaximizeHeight, forKey: .almostMaximizeHeight)
        try container.encode(minimumWindowWidth, forKey: .minimumWindowWidth)
        try container.encode(minimumWindowHeight, forKey: .minimumWindowHeight)
        try container.encode(sizeOffset, forKey: .sizeOffset)
        try container.encode(widthStepSize, forKey: .widthStepSize)
        try container.encode(specifiedWidth, forKey: .specifiedWidth)
        try container.encode(specifiedHeight, forKey: .specifiedHeight)
        try container.encode(cascadeDelta, forKey: .cascadeDelta)
        try container.encode(traverseSingleScreen, forKey: .traverseSingleScreen)
        try container.encode(useCursorScreenDetection, forKey: .useCursorScreenDetection)
        try container.encode(attemptMatchOnNextPrevDisplay, forKey: .attemptMatchOnNextPrevDisplay)
        try container.encode(autoMaximize, forKey: .autoMaximize)
        try container.encode(combinedDisplayMode, forKey: .combinedDisplayMode)
        try container.encode(screensOrderedBy, forKey: .screensOrderedBy)
        try container.encode(resizeOnDirectionalMove, forKey: .resizeOnDirectionalMove)
        try container.encode(centeredDirectionalMove, forKey: .centeredDirectionalMove)
        try container.encode(halvesPreserveOtherAxisSize, forKey: .halvesPreserveOtherAxisSize)
        try container.encode(moveCursorAcrossDisplays, forKey: .moveCursorAcrossDisplays)
        try container.encode(moveCursorWithActions, forKey: .moveCursorWithActions)
        try container.encode(centerHalfCycles, forKey: .centerHalfCycles)
        try container.encode(applyGapsToMaximize, forKey: .applyGapsToMaximize)
        try container.encode(applyGapsToMaximizeHeight, forKey: .applyGapsToMaximizeHeight)
        try container.encode(windowSnapping, forKey: .windowSnapping)
        try container.encode(unsnapRestore, forKey: .unsnapRestore)
        try container.encode(animateFootprint, forKey: .animateFootprint)
        try container.encode(hapticFeedbackOnSnap, forKey: .hapticFeedbackOnSnap)
        try container.encode(missionControlDragging, forKey: .missionControlDragging)
        try container.encode(sixthsSnapArea, forKey: .sixthsSnapArea)
        try container.encode(snapMargins, forKey: .snapMargins)
        try container.encode(snapAreas, forKey: .snapAreas)
        try container.encode(footprintAlpha, forKey: .footprintAlpha)
        try container.encode(ignoredBundleIDs, forKey: .ignoredBundleIDs)
        try container.encode(ignoreDragSnapToo, forKey: .ignoreDragSnapToo)
        try container.encode(showAdditionalSizesInMenu, forKey: .showAdditionalSizesInMenu)
        try container.encodeIfPresent(doubleClickTitleBarAction, forKey: .doubleClickTitleBarAction)
        try container.encode(doubleClickTitleBarRestore, forKey: .doubleClickTitleBarRestore)
        try container.encode(greenButtonOverride, forKey: .greenButtonOverride)
        try container.encode(todoMode, forKey: .todoMode)
        try container.encode(todoSide, forKey: .todoSide)
        try container.encode(todoWidth, forKey: .todoWidth)
        try container.encode(todoIsFraction, forKey: .todoIsFraction)
        try container.encodeIfPresent(todoBundleID, forKey: .todoBundleID)
        try container.encode(shortcuts, forKey: .shortcuts)
    }
}
