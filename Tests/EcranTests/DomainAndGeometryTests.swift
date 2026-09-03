import AppKit
import Domain
@testable import EcranCore
import Foundation
import Infrastructure
import WindowGeometry

extension EcranSelfTests {
    @MainActor
    static func runIdentityAndSettingsTests(_ test: TestHarness) {
        let shipped = AppIdentity.shipped
        let development = AppIdentity.development
        test.expectEqual(shipped.bundleIdentifier, "com.jean.ecran", "shipped bundle id")
        test.expectEqual(development.bundleIdentifier, "com.jean.ecran.dev", "dev bundle id")
        test.expect(!shipped.isDevelopment, "shipped identity is not marked development")
        test.expect(development.isDevelopment, "dev identity is marked development")
        test.expectEqual(shipped.displayName, "Ecran", "shipped display name")
        test.expectEqual(development.displayName, "Ecran Dev", "dev display name")
        test.expectEqual(shipped.dataDirectoryName, ".ecran", "shipped settings directory")
        test.expectEqual(development.dataDirectoryName, ".ecran-dev", "dev settings directory")

        let defaults = AppSettings.default
        test.expectEqual(ModifierKey.command.glyph, "⌘", "command glyph")
        test.expectEqual(ModifierKey.option.glyph, "⌥", "option glyph")
        test.expectEqual(defaults.modifierKey, .command, "same-app modifier")
        test.expectEqual(defaults.triggerKey, .grave, "same-app trigger")
        test.expect(defaults.appSwitcherEnabled, "app switcher on")
        test.expect(defaults.showWindowsFromAllSpaces, "all Spaces default")
        test.expectEqual(defaults.windowDisplayStyle, .initials, "initials default")
        test.expectEqual(defaults.switcherVerticalPosition, 0.39, "golden ratio")
        test.expectEqual(defaults.colorScheme, .system, "system color")
        test.expect(defaults.shortcuts[.leftHalf] != nil, "recommended left half shortcut")

        do {
            let json = """
            { "modifierKey": "function", "triggerKey": "Space", "showWindowPreviews": true }
            """.data(using: .utf8)!
            let decoded = try JSONDecoder().decode(AppSettings.self, from: json)
            test.expectEqual(decoded.modifierKey, .function, "legacy modifier")
            test.expectEqual(decoded.triggerKey, .space, "legacy trigger")
            test.expectEqual(decoded.windowDisplayStyle, .preview, "legacy preview mapping")
            test.expect(decoded.showWindowsFromAllSpaces, "missing keys keep defaults")
        } catch {
            test.expect(false, "tolerant settings decode: \(error)")
        }

        let box = IsolatedBox.make()
        defer { box.tearDown() }
        var settings = AppSettings.default
        settings.gapSize = 12
        settings.showWindowsFromAllSpaces = false
        box.store.save(settings)
        let loaded = JSONSettingsStore(fileURL: box.store.fileURL).load()
        test.expectEqual(loaded.gapSize, 12, "persisted gap")
        test.expect(!loaded.showWindowsFromAllSpaces, "persisted Spaces toggle")
    }

    @MainActor
    static func runTitleExtractionTests(_ test: TestHarness) {
        test.expectEqual(
            TitleExtractor.extract("MyProject — main.swift — Edited", using: .beforeFirstSeparator, customSeparator: " — "),
            "MyProject",
            "before first custom separator"
        )
        test.expectEqual(
            TitleExtractor.extract("Folder - Sub - readme.md", using: .afterLastSeparator, customSeparator: " - "),
            "readme.md",
            "after last custom separator"
        )
        test.expectEqual(
            TitleExtractor.extract("WebApp | localhost", using: .firstPart, customSeparator: nil),
            "WebApp",
            "first part common separator"
        )
        test.expectEqual(
            TitleExtractor.extract("WebApp | localhost", using: .lastPart, customSeparator: nil),
            "localhost",
            "last part common separator"
        )
        test.expectEqual(
            TitleExtractor.extract("main.swift — Lineup — Edited", using: .fullTitle, customSeparator: nil),
            "main.swift — Lineup — Edited",
            "full title"
        )
        test.expectEqual(
            TitleExtractor.extract("Untitled", using: .beforeFirstSeparator, customSeparator: " — "),
            "Untitled",
            "no separator"
        )
        test.expectEqual(
            TitleExtractor.extract("", using: .firstPart, customSeparator: nil),
            "",
            "empty title"
        )
        test.expectEqual(
            TitleExtractor.extract("  Project   -   file  ", using: .beforeFirstSeparator, customSeparator: " - "),
            "Project",
            "trimmed result"
        )
        let extracted = TitleExtractor.extract(
            "Repo — file.swift",
            bundleID: "com.apple.dt.Xcode",
            appConfigs: TitleExtractor.builtInAppConfigs,
            defaultStrategy: .fullTitle,
            defaultSeparator: " - "
        )
        test.expectEqual(extracted, "Repo", "Xcode built-in config")
    }

    @MainActor
    static func runWindowClassificationTests(_ test: TestHarness) {
        test.expect(WindowClassification.acceptsWindowSubrole(WindowClassification.standardSubrole), "standard window")
        test.expect(WindowClassification.acceptsWindowSubrole(WindowClassification.dialogSubrole), "Safari minimized dialog")
        test.expect(WindowClassification.acceptsWindowSubrole(nil), "missing subrole")
        test.expect(!WindowClassification.acceptsWindowSubrole(WindowClassification.floatingSubrole), "floating rejected")
        test.expect(!WindowClassification.acceptsWindowSubrole(WindowClassification.systemDialogSubrole), "system dialog rejected")
        test.expect(!WindowClassification.acceptsWindowSubrole(""), "empty rejected")
        test.expect(
            SpaceMembership.isOnOtherSpace(windowSpaces: [200], currentSpaces: [100], isMinimized: false),
            "fullscreen Space is other than the current fullscreen Space"
        )
        test.expect(
            !SpaceMembership.isOnOtherSpace(windowSpaces: [100], currentSpaces: [100], isMinimized: false),
            "window on the current fullscreen Space"
        )
        test.expect(
            !SpaceMembership.isOnOtherSpace(windowSpaces: [], currentSpaces: [100], isMinimized: false),
            "unknown Space stays current"
        )
        test.expect(
            !SpaceMembership.isOnOtherSpace(windowSpaces: [200], currentSpaces: [100], isMinimized: true),
            "minimized is not other-Space"
        )
        test.expect(WindowClassification.isValidWindowLayer(0, forBundleID: "com.apple.Safari"), "layer 0")
        test.expect(
            WindowClassification.isValidWindowLayer(8, forBundleID: "com.valvesoftware.steam"),
            "Steam non-zero layer"
        )
        test.expect(
            !WindowClassification.isValidWindowLayer(8, forBundleID: "com.apple.Safari"),
            "non-Steam non-zero layer"
        )
        let monogram = Monogram.from(title: "Ecran - Settings")
        test.expectEqual(monogram.initials, "ES", "monogram initials")
        test.expectEqual(SwitcherPresentation.windowCountLabel(0), "No windows", "zero windows")
        test.expectEqual(SwitcherPresentation.windowCountLabel(1), "1 window", "single window")
        test.expectEqual(SwitcherPresentation.windowCountLabel(4), "4 windows", "many windows")
        test.expectEqual(
            SwitcherPresentation.spaceLabel(isOnOtherSpace: true, spaceIndex: 3),
            Optional("Desktop 3"),
            "numbered desktop"
        )
        test.expectEqual(
            SwitcherPresentation.spaceLabel(isOnOtherSpace: true, spaceIndex: 0),
            Optional("Other desktop"),
            "unnumbered desktop"
        )
        test.expect(
            SwitcherPresentation.spaceLabel(isOnOtherSpace: false, spaceIndex: 2) == nil,
            "current desktop has no space label"
        )

        test.expect(
            AppSwitcherListing.includes(
                isRegular: true,
                bundleID: "com.apple.Safari",
                excludingBundleID: "com.jean.ecran.dev"
            ),
            "regular apps belong in Command-Tab"
        )
        test.expect(
            !AppSwitcherListing.includes(
                isRegular: false,
                bundleID: "com.example.menubar",
                excludingBundleID: "com.jean.ecran.dev"
            ),
            "accessory menu-bar apps stay out"
        )
        test.expect(
            !AppSwitcherListing.includes(
                isRegular: true,
                bundleID: nil,
                excludingBundleID: nil
            ),
            "helpers without a bundle ID stay out"
        )
        test.expect(
            !AppSwitcherListing.includes(
                isRegular: true,
                bundleID: "com.jean.ecran.dev",
                excludingBundleID: "com.jean.ecran.dev"
            ),
            "Ecran itself stays out"
        )
        test.expect(
            AppSwitcherListing.prefersIncoming(
                existingActive: false,
                existingZOrder: 3,
                incomingActive: true,
                incomingZOrder: 8
            ),
            "active process wins the bundle"
        )
        test.expect(
            !AppSwitcherListing.prefersIncoming(
                existingActive: false,
                existingZOrder: 1,
                incomingActive: false,
                incomingZOrder: 4
            ),
            "frontmost process wins when neither is active"
        )
    }

    @MainActor
    static func runWindowLayoutTests(_ test: TestHarness) {
        let screen = ScreenFrame(
            visible: CGRect(x: 0, y: 0, width: 1200, height: 800),
            full: CGRect(x: 0, y: 0, width: 1200, height: 800),
            isMain: true,
            hasNotch: false,
            index: 0
        )
        let settings = AppSettings.default
        let window = CGRect(x: 100, y: 100, width: 400, height: 300)
        func layout(_ action: WindowAction, last: LastWindowAction? = nil) -> LayoutResult {
            WindowLayoutEngine.calculate(
                LayoutRequest(
                    action: action,
                    window: window,
                    screen: screen,
                    screens: [screen],
                    lastAction: last,
                    settings: settings
                )
            )
        }
        let left = layout(.leftHalf)
        test.expect(abs(left.rect.width - 600) < 1, "left half width")
        test.expectEqual(left.rect.minX, 0, "left half origin")
        let right = layout(.rightHalf)
        test.expect(abs(right.rect.minX - 600) < 1, "right half origin")
        let maximize = layout(.maximize)
        test.expectEqual(maximize.rect, screen.visible, "maximize fills visible frame")
        let first = layout(.firstThird)
        test.expect(abs(first.rect.width - 400) < 1, "first third width")
        let last = layout(.lastThird)
        test.expect(abs(last.rect.minX - 800) < 1, "last third origin")
        let top = layout(.topHalf)
        test.expectEqual(top.rect.minY, 0, "top half sits at the top")
        test.expect(abs(top.rect.height - 400) < 1, "top half height")
        let bottom = layout(.bottomHalf)
        test.expect(abs(bottom.rect.minY - 400) < 1, "bottom half sits at the bottom")
        test.expect(abs(bottom.rect.maxY - 800) < 1, "bottom half reaches the bottom")
        let topLeft = layout(.topLeft)
        test.expectEqual(topLeft.rect.minY, 0, "top left sits at the top")
        test.expect(abs(topLeft.rect.width - 600) < 1 && abs(topLeft.rect.height - 400) < 1, "top left quarter")
        let bottomLeft = layout(.bottomLeft)
        test.expect(abs(bottomLeft.rect.minY - 400) < 1, "bottom left sits at the bottom")
        let topSixth = layout(.topLeftSixth)
        test.expectEqual(topSixth.rect.minY, 0, "top sixth sits at the top")
        let bottomSixth = layout(.bottomLeftSixth)
        test.expect(bottomSixth.rect.minY > 300, "bottom sixth sits below the midline")
        let topThird = layout(.topVerticalThird)
        test.expectEqual(topThird.rect.minY, 0, "top vertical third sits at the top")
        let bottomThird = layout(.bottomVerticalThird)
        test.expect(bottomThird.rect.maxY > 790, "bottom vertical third reaches the bottom")
        let ninth = layout(.middleCenterNinth)
        test.expect(abs(ninth.rect.width - 400) < 1 && abs(ninth.rect.height - 800 / 3) < 2, "center ninth")
        let tiles = WindowLayoutEngine.tile([window, window, window, window], in: screen.visible, settings: settings)
        test.expectEqual(tiles.count, 4, "tile count")
        test.expect(tiles[0].width > 0 && tiles[3].height > 0, "tile sizes")
        let reversed = WindowLayoutEngine.reverse([CGRect(x: 0, y: 0, width: 200, height: 100)], in: screen.visible)
        test.expect(abs(reversed[0].minX - 1000) < 1, "reverse mirrors x")

        var gapped = settings
        gapped.gapSize = 10
        let gappedLeft = WindowLayoutEngine.calculate(
            LayoutRequest(action: .leftHalf, window: window, screen: screen, screens: [screen], settings: gapped)
        )
        test.expect(gappedLeft.rect.width < left.rect.width, "gaps shrink shared half")
    }

    @MainActor
    static func runSnapAndURLTests(_ test: TestHarness) {
        let screen = ScreenFrame(
            visible: CGRect(x: 0, y: 0, width: 1440, height: 900),
            full: CGRect(x: 0, y: 0, width: 1440, height: 900),
            isMain: true,
            hasNotch: false,
            index: 0
        )
        let settings = AppSettings.default
        let left = SnapDetection.hit(cursor: CGPoint(x: 2, y: 450), screen: screen, settings: settings)
        test.expectEqual(left?.action, .leftHalf, "left edge snap")
        let top = SnapDetection.hit(cursor: CGPoint(x: 720, y: 2), screen: screen, settings: settings)
        test.expectEqual(top?.action, .maximize, "top edge snap")
        let corner = SnapDetection.hit(cursor: CGPoint(x: 2, y: 2), screen: screen, settings: settings)
        test.expectEqual(corner?.action, .topLeft, "top-left corner snap")
        var disabled = settings
        disabled.windowSnapping = false
        test.expect(SnapDetection.hit(cursor: CGPoint(x: 2, y: 450), screen: screen, settings: disabled) == nil, "snap off")
        test.expect(
            SnapDrag.isWindowMove(
                from: CGRect(x: 80, y: 80, width: 400, height: 300),
                to: CGRect(x: 120, y: 90, width: 400, height: 300)
            ),
            "origin change is a window move"
        )
        test.expect(
            SnapDrag.isWindowMove(
                from: CGRect(x: 80, y: 80, width: 400, height: 300),
                to: CGRect(x: 80, y: 80, width: 400, height: 300)
            ) == false,
            "slider drags that leave the window still are not a move"
        )
        test.expect(
            SnapDrag.isWindowMove(
                from: CGRect(x: 80, y: 80, width: 400, height: 300),
                to: CGRect(x: 81, y: 80, width: 400, height: 300)
            ) == false,
            "1pt AX jitter is not a move"
        )
        test.expect(
            SnapDrag.isWindowMove(
                from: CGRect(x: 80, y: 80, width: 400, height: 300),
                to: CGRect(x: 84, y: 80, width: 400, height: 300)
            ),
            "4pt origin change is a move"
        )

        let usable = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let topLeft = CGRect(x: 0, y: 0, width: 500, height: 400)
        let band = CooperativeCorner.complementaryBand(action: .topLeft, placed: topLeft, usable: usable)
        test.expectEqual(
            band,
            Optional(CGRect(x: 500, y: 0, width: 500, height: 400)),
            "top-left neighbor band"
        )
        test.expect(
            CooperativeCorner.shouldResize(
                CGRect(x: 520, y: 10, width: 460, height: 380),
                into: band ?? .zero,
                excluding: topLeft
            ),
            "window already in the band is resized"
        )
        test.expect(
            CooperativeCorner.shouldResize(
                CGRect(x: 500, y: 0, width: 500, height: 800),
                into: band ?? .zero,
                excluding: topLeft
            ) == false,
            "full right half is not crushed into a top band"
        )
        test.expect(
            CooperativeCorner.complementaryBand(action: .leftHalf, placed: topLeft, usable: usable) == nil,
            "halves are not cooperative corners"
        )

        test.expectEqual(WindowAction.parse(name: "left-half"), .leftHalf, "kebab parse")
        test.expectEqual(WindowAction.parse(name: "left-side"), .leftHalf, "alias parse")
        test.expectEqual(WindowAction.parse(name: "almost-maximize"), .almostMaximize, "almost maximize")
        let actionURL = URL(string: "ecran://execute-action?name=right-half")!
        test.expectEqual(URLCommand.parse(url: actionURL)?.kind, .action(.rightHalf), "action URL")
        let taskURL = URL(string: "ecran://execute-task?name=ignore-app&app-bundle-id=com.apple.Safari")!
        if case .task(let task, let bundle)? = URLCommand.parse(url: taskURL)?.kind {
            test.expectEqual(task, .ignoreApp, "ignore task")
            test.expectEqual(bundle, "com.apple.Safari", "ignore bundle")
        } else {
            test.expect(false, "parse ignore-app URL")
        }
        test.expectEqual(URLCommand.parse(url: URL(string: "ecran://settings")!)?.kind, .settings, "settings URL")
        test.expectEqual(URLCommand.parse(url: URL(string: "rectangle://settings")!)?.kind, .settings, "rectangle settings URL")
        test.expect(URLCommand.parse(url: URL(string: "https://example.com")!) == nil, "foreign URL rejected")
        test.expect(URLCommand.parse(url: URL(string: "rectangle://execute-action?name=left-half")!)?.kind == .action(.leftHalf), "rectangle scheme")

        let leftShort = SnapDetection.hit(cursor: CGPoint(x: 2, y: 50), screen: screen, settings: settings)
        test.expectEqual(leftShort?.action, .topHalf, "left-top short edge is a half")
        let bottomCenter = SnapDetection.hit(cursor: CGPoint(x: 720, y: 898), screen: screen, settings: settings)
        test.expectEqual(bottomCenter?.action, .centerThird, "bottom center third")
        let escalated = SnapDetection.hit(
            cursor: CGPoint(x: 720, y: 898),
            screen: screen,
            settings: settings,
            prior: SnapHit(zone: .bottomLeftThird, action: .firstThird, rect: .zero)
        )
        test.expectEqual(escalated?.action, .firstTwoThirds, "bottom center escalates from first third")
        var sixths = settings
        sixths.sixthsSnapArea = true
        let sixth = SnapDetection.hit(cursor: CGPoint(x: 2, y: 2), screen: screen, settings: sixths)
        test.expectEqual(sixth?.action, .topLeftSixth, "sixths replace corner quarters")
    }

    @MainActor
    static func runVerifiedBugfixTests(_ test: TestHarness) {
        test.expect(
            !TitleBarRestore.shouldRestore(
                enabled: false,
                action: .maximize,
                historyMatches: true,
                lastAction: .maximize
            ),
            "restore toggle off does not restore maximize"
        )
        test.expect(
            TitleBarRestore.shouldRestore(
                enabled: true,
                action: .maximize,
                historyMatches: true,
                lastAction: .maximize
            ),
            "restore toggle on restores matching maximize"
        )
        test.expect(
            !TitleBarRestore.shouldRestore(
                enabled: true,
                action: .maximize,
                historyMatches: false,
                lastAction: .maximize
            ),
            "restore needs a matching last frame"
        )
        test.expect(SwitcherHold.shouldDismissOnShow(modifierDown: false, held: false), "tap dismisses")
        test.expect(!SwitcherHold.shouldDismissOnShow(modifierDown: true, held: false), "held modifier stays open")
        test.expect(!SwitcherHold.shouldDismissOnShow(modifierDown: false, held: true), "double-tap hold stays open")

        test.expect(!WindowClassification.acceptsWindowSubrole(WindowClassification.floatingSubrole), "floating is not snappable")

        let screen = ScreenFrame(
            visible: CGRect(x: 0, y: 0, width: 1440, height: 900),
            full: CGRect(x: 0, y: 0, width: 1440, height: 900),
            isMain: true,
            hasNotch: false,
            index: 0
        )
        var preserve = AppSettings.default
        preserve.halvesPreserveOtherAxisSize = true
        let short = CGRect(x: 100, y: 200, width: 400, height: 250)
        let hit = SnapDetection.hit(
            cursor: CGPoint(x: 2, y: 450),
            screen: screen,
            settings: preserve,
            window: short
        )
        test.expectEqual(hit?.action, .leftHalf, "preserve-axis snap is still a half")
        test.expectEqual(hit?.rect.height, 250, "snap footprint keeps the dragged height")
        test.expectEqual(hit?.rect.minY, 200, "snap footprint keeps the dragged y")

        let other = ScreenFrame(
            visible: CGRect(x: 1440, y: 0, width: 1440, height: 900),
            full: CGRect(x: 1440, y: 0, width: 1440, height: 900),
            isMain: false,
            hasNotch: false,
            index: 1
        )
        var traverse = AppSettings.default
        traverse.traverseSingleScreen = true
        let stayed = WindowLayoutEngine.calculate(
            LayoutRequest(
                action: .nextDisplay,
                window: short,
                screen: screen,
                screens: [screen, other],
                settings: traverse
            )
        )
        test.expectEqual(stayed.screenIndex, 0, "traverseSingleScreen stays on this display")
        traverse.traverseSingleScreen = false
        let moved = WindowLayoutEngine.calculate(
            LayoutRequest(
                action: .nextDisplay,
                window: short,
                screen: screen,
                screens: [screen, other],
                settings: traverse
            )
        )
        test.expectEqual(moved.screenIndex, 1, "next display crosses when traverse is off")

        var todo = AppSettings.default
        todo.todoMode = true
        todo.todoWidth = 200
        todo.todoSide = .left
        todo.screenEdgeGapLeft = 12
        let reserved = GapPolicy.usableFrame(for: screen, settings: todo)
        let edgesOnly = GapPolicy.usableFrame(for: screen, settings: todo, reserveTodo: false)
        test.expect(abs(reserved.minX - 212) < 1, "other windows reserve todo and edge gap")
        test.expect(abs(edgesOnly.minX - 12) < 1, "todo reflow keeps only the edge gap")

        do {
            var settings = AppSettings.default
            settings.appTitleConfigs["com.example.app"] = AppTitleConfig(
                strategy: .beforeFirstSeparator,
                customSeparator: " - "
            )
            let data = try ConfigImportExport.exportTitles(settings)
            let titles = try JSONDecoder().decode(TitleConfigDocument.self, from: data)
            test.expect(titles.appTitleConfigs["com.example.app"] != nil, "titles export keeps app configs")
            test.expect((try? JSONDecoder().decode(ExportedConfig.self, from: data)) == nil, "titles export is not a full config")
            let imported = try ConfigImportExport.importSettings(from: data, into: .default, titlesOnly: true)
            test.expect(imported.appTitleConfigs["com.example.app"] != nil, "titles-only import reads the titles document")
        } catch {
            test.expect(false, "titles export/import: \(error)")
        }

        test.expectEqual(
            AppIdentity.current.openSettingsNotification,
            Notification.Name(AppIdentity.current.bundleIdentifier + ".openSettings"),
            "open-settings notification is bundle-scoped"
        )
    }

    @MainActor
    static func runIntegrationAndParityTests(_ test: TestHarness) {
        test.expect(FeatureIsolation.placementHotkeysEnabled(switcherOpen: true, frontmostIgnored: false) == false, "switcher suspends placement")
        test.expect(FeatureIsolation.placementHotkeysEnabled(switcherOpen: false, frontmostIgnored: true) == false, "ignored app suspends placement")
        test.expect(FeatureIsolation.placementHotkeysEnabled(switcherOpen: false, frontmostIgnored: false), "placement on when idle")
        test.expect(FeatureIsolation.switcherHotkeysEnabled(frontmostIgnored: true), "switcher stays live in ignored apps")
        test.expect(
            FeatureIsolation.snapEnabled(windowSnapping: true, ignoreDragSnapToo: true, switcherOpen: true, frontmostIgnored: false) == false,
            "snap off while switcher is open"
        )
        test.expect(
            FeatureIsolation.snapEnabled(windowSnapping: true, ignoreDragSnapToo: true, switcherOpen: false, frontmostIgnored: true) == false,
            "snap off in ignored apps"
        )
        test.expect(
            FeatureIsolation.snapEnabled(windowSnapping: true, ignoreDragSnapToo: false, switcherOpen: false, frontmostIgnored: true),
            "snap can stay on when ignore-snap is off"
        )

        var shared = AppSettings.default
        shared.shortcuts[.leftHalf] = .optionControl(123)
        shared.shortcuts[.firstThird] = .optionControl(123)
        let groups = ShortcutCycle.groups(from: shared.shortcuts)
        test.expect(groups.contains { $0.isCycle && $0.actions.contains(.leftHalf) && $0.actions.contains(.firstThird) }, "same chord cycles")
        test.expectEqual(ShortcutCycle.next(after: .leftHalf, in: [.leftHalf, .firstThird]), .firstThird, "cycle advances")
        test.expectEqual(ShortcutCycle.next(after: nil, in: [.leftHalf, .firstThird]), .leftHalf, "cycle starts at first")

        test.expectEqual(SwitcherColorScheme.cyberpunk.palette.primaryGreen, 1, "cyberpunk primary")
        test.expectEqual(SwitcherColorScheme.sunset.palette.primaryRed, 1, "sunset primary")
        test.expect(SwitcherColorScheme.system.palette.usesSystemAccent, "system accent")

        let screen = ScreenFrame(
            visible: CGRect(x: 0, y: 0, width: 1200, height: 800),
            full: CGRect(x: 0, y: 0, width: 1200, height: 800),
            isMain: true,
            hasNotch: false,
            index: 0
        )
        var preserve = AppSettings.default
        preserve.halvesPreserveOtherAxisSize = true
        let window = CGRect(x: 100, y: 200, width: 400, height: 250)
        let preserved = WindowLayoutEngine.calculate(
            LayoutRequest(action: .leftHalf, window: window, screen: screen, screens: [screen], settings: preserve)
        )
        test.expectEqual(preserved.rect.minY, 200, "halves keep y")
        test.expectEqual(preserved.rect.height, 250, "halves keep height")

        var todo = AppSettings.default
        todo.todoMode = true
        todo.todoWidth = 200
        todo.todoSide = .left
        let todoPin = WindowLayoutEngine.calculate(
            LayoutRequest(action: .leftTodo, window: window, screen: screen, screens: [screen], settings: todo)
        )
        test.expect(abs(todoPin.rect.width - 200) < 1, "todo pins to the strip")
        test.expectEqual(todoPin.rect.minX, 0, "todo strip on the left")

        let reserved = GapPolicy.usableFrame(for: screen, settings: todo)
        test.expect(abs(reserved.minX - 200) < 1, "todo mode insets other windows")

        for action in WindowAction.allCases {
            let result = WindowLayoutEngine.calculate(
                LayoutRequest(action: action, window: window, screen: screen, screens: [screen], settings: .default)
            )
            test.expect(result.rect.width >= 0 && result.rect.height >= 0, "layout covers \(action.rawValue)")
        }

        test.expect(WindowAction.menuOrder.contains(.leftHalf) && WindowAction.menuOrder.contains(.tileAll), "core menu actions")
        test.expect(WindowAction.additionalSizes.contains(.displayOne) && WindowAction.additionalSizes.contains(.topLeftNinth), "extra sizes")
        test.expect(AppSettings.default.ignoreDragSnapToo, "ignore-app also blocks snap by default")
    }

    @MainActor
    static func runStatusMenuTests(_ test: TestHarness) {
        test.expect(WindowAction.leftHalf.firstInGroup, "left half starts a group")
        test.expect(!WindowAction.rightHalf.firstInGroup, "right half stays in the half group")
        test.expect(WindowAction.topLeft.firstInGroup, "corners start a group")
        test.expect(WindowAction.maximize.firstInGroup, "maximize starts a group")
        test.expectEqual(WindowAction.leftHalf.category, .halves, "halves fold together")
        test.expectEqual(WindowAction.topLeft.category, .corners, "corners fold together")
        test.expectEqual(WindowAction.maximize.category, .size, "size folds together")
        test.expectEqual(WindowAction.firstFourth.menuSubcategory, .fourths, "fourths nest")
        test.expectEqual(WindowAction.moveLeft.menuSubcategory, .move, "move nests")
        test.expectEqual(WindowAction.firstThird.menuSubcategory, .thirds, "thirds nest")
        test.expect(WindowAction.topVerticalThird.firstInGroup, "vertical thirds start a group")

        let left = WindowAction.leftHalf.menuIconUnitRect
        test.expect(abs(left.width - 0.5) < 0.001, "left half fills the left")
        test.expectEqual(left.x, 0, "left half origin")
        let topLeft = WindowAction.topLeft.menuIconUnitRect
        test.expect(abs(topLeft.y - 0.5) < 0.001, "top left is in the upper half")
        let lastTwo = WindowAction.lastTwoThirds.menuIconUnitRect
        test.expect(abs(lastTwo.x - (1.0 / 3.0)) < 0.001, "last two thirds start at one third")

        for action in WindowAction.allCases {
            let region = action.menuIconUnitRect
            test.expect(region.width > 0 && region.height > 0, "icon region for \(action.rawValue)")
            test.expect(region.maxX <= 1.001 && region.maxY <= 1.001, "icon region stays in unit square \(action.rawValue)")
        }

        let icon = PlacementIcon.image(for: .leftHalf)
        test.expect(icon.isTemplate, "placement icon is a template")
        test.expectEqual(icon.size.width, 18, "placement icon width")
        test.expectEqual(icon.size.height, 12, "placement icon height")

        test.expectEqual(KeyboardLayout.specialKeyLabel(for: 123), "←", "left arrow glyph")
        test.expectEqual(KeyboardLayout.specialKeyLabel(for: 124), "→", "right arrow glyph")
        test.expectEqual(KeyboardLayout.specialKeyLabel(for: 126), "↑", "up arrow glyph")
        test.expectEqual(KeyboardLayout.specialKeyLabel(for: 125), "↓", "down arrow glyph")
        test.expectEqual(
            KeyboardLayout.displayLabel(for: .optionControl(123)),
            "⌃⌥←",
            "left half chord shows the arrow"
        )
        test.expectEqual(
            KeyboardLayout.displayLabel(for: .optionControl(36)),
            "⌃⌥↩",
            "maximize chord shows return"
        )
        test.expect(KeyboardLayout.displayLabel(for: .optionControl(123)).contains("←"), "arrow is not dropped")

        let leftShortcut = MenuShortcut.equivalent(for: .optionControl(123))
        test.expectEqual(leftShortcut?.key, String(UnicodeScalar(NSLeftArrowFunctionKey)!), "left arrow equivalent")
        test.expect(leftShortcut?.modifiers.contains(.option) == true, "option in left half")
        test.expect(leftShortcut?.modifiers.contains(.control) == true, "control in left half")

        let maximize = MenuShortcut.equivalent(for: .optionControl(36))
        test.expectEqual(maximize?.key, "\r", "return equivalent")

        let corner = MenuShortcut.equivalent(for: .optionControl(32))
        test.expectEqual(corner?.key, "u", "U key equivalent")
    }

    @MainActor
    static func runSecurityHardeningTests(_ test: TestHarness) {
        let box = IsolatedBox.make()
        defer { box.tearDown() }
        box.store.save(.default)
        let attributes = try? FileManager.default.attributesOfItem(atPath: box.store.fileURL.path)
        let permissions = attributes?[.posixPermissions] as? NSNumber
        test.expectEqual(permissions?.intValue ?? 0, 0o600, "settings file is owner-only")

        let redacted = LogRedactor.redact("token=supersecrettokenvalue123\nsecond line")
        test.expect(redacted.contains("<redacted>"), "token redacted")
        test.expect(redacted.contains("multiline details omitted"), "multiline omitted")
        test.expect(!redacted.contains("supersecrettokenvalue123"), "secret removed")

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let pathRedacted = LogRedactor.redact("wrote \(home)/secret.json")
        test.expect(pathRedacted.contains("~/secret.json"), "home path redacted")
        test.expect(WindowAction.allCases.count >= 120, "full Rectangle action catalog")
    }
}
