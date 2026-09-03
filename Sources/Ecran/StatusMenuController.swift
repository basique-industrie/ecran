import AppKit
import Domain
import Infrastructure

@MainActor
final class StatusMenuController: NSObject, NSMenuDelegate {
    private let runtime: EcranRuntime
    private let onShowSettings: () -> Void
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var settingsObserver: NSObjectProtocol?
    private var lastAdditionalSizes = false
    private var lastTodoMode = false

    private static let additionalCategories: Set<WindowActionCategory> = [
        .eighths, .ninths, .twelfths, .sixteenths, .cornerThirds,
    ]
    private static let primaryCategories: Set<WindowActionCategory> = [
        .halves, .corners, .thirds, .size, .position,
    ]

    init(runtime: EcranRuntime, onShowSettings: @escaping () -> Void) {
        self.runtime = runtime
        self.onShowSettings = onShowSettings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureStatusItem()
        menu.delegate = self
        menu.autoenablesItems = false
        rebuild()
        applyVisibility()
        runtime.onMenuBarVisibilityChanged = { [weak self] in
            self?.applyVisibility()
        }
        settingsObserver = NotificationCenter.default.addObserver(
            forName: .settingsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.settingsChanged()
            }
        }
    }

    func invalidate() {
        if let settingsObserver {
            NotificationCenter.default.removeObserver(settingsObserver)
        }
        runtime.onMenuBarVisibilityChanged = nil
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    func menuWillOpen(_ menu: NSMenu) {
        applyOpenState(to: menu)
    }

    func menuDidClose(_ menu: NSMenu) {
        clearShortcuts(in: menu)
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        let symbol = NSImage(systemSymbolName: MenuBarIdentityIcon.symbolName, accessibilityDescription: AppIdentity.current.displayName)
        symbol?.isTemplate = true
        button.image = symbol?.withSymbolConfiguration(.init(pointSize: 13, weight: .regular)) ?? symbol
        button.image?.isTemplate = true
        button.toolTip = AppIdentity.current.displayName
        statusItem.menu = menu
    }

    private func settingsChanged() {
        applyVisibility()
        let additional = runtime.settings.showAdditionalSizesInMenu
        let todo = runtime.settings.todoMode
        if additional != lastAdditionalSizes || todo != lastTodoMode {
            rebuild()
        }
    }

    private func applyVisibility() {
        statusItem.isVisible = !runtime.settings.hideMenuBarIcon
    }

    private func rebuild() {
        lastAdditionalSizes = runtime.settings.showAdditionalSizesInMenu
        lastTodoMode = runtime.settings.todoMode
        menu.removeAllItems()

        var categoryMenus: [WindowActionCategory: CategoryMenu] = [:]

        for action in actionsToShow(showAdditional: lastAdditionalSizes) {
            let category = action.category
            let bucket: CategoryMenu
            if let existing = categoryMenus[category] {
                bucket = existing
            } else {
                let submenu = NSMenu(title: category.displayName)
                submenu.delegate = self
                submenu.autoenablesItems = false
                bucket = CategoryMenu(menu: submenu, category: category)
                categoryMenus[category] = bucket
            }
            if bucket.menu.numberOfItems > 0, action.firstInGroup {
                bucket.menu.addItem(.separator())
            }
            bucket.menu.addItem(makeActionItem(action))
        }

        let ordered = categoryMenus.values.sorted { $0.category.menuOrder < $1.category.menuOrder }
        var didSeparateSecondary = false
        for categoryMenu in ordered {
            if !didSeparateSecondary, !Self.primaryCategories.contains(categoryMenu.category), !menu.items.isEmpty {
                menu.addItem(.separator())
                didSeparateSecondary = true
            }
            let item = NSMenuItem(title: categoryMenu.category.displayName, action: nil, keyEquivalent: "")
            item.image = categoryMenu.menu.items.lazy.compactMap(\.image).first
            menu.addItem(item)
            menu.setSubmenu(categoryMenu.menu, for: item)
        }

        if !ordered.isEmpty {
            menu.addItem(.separator())
        }
        appendFooter()
    }

    private func actionsToShow(showAdditional: Bool) -> [WindowAction] {
        var seen = Set<WindowAction>()
        var actions: [WindowAction] = []
        let source = WindowAction.menuOrder + (showAdditional ? WindowAction.additionalSizes : [])
        for action in source {
            guard seen.insert(action).inserted else { continue }
            if action.category == .todo && !runtime.settings.todoMode {
                continue
            }
            if Self.additionalCategories.contains(action.category), !showAdditional {
                continue
            }
            if action.category == .displays, action != .nextDisplay, action != .previousDisplay, !showAdditional {
                continue
            }
            actions.append(action)
        }
        return actions
    }

    private func appendFooter() {
        let settings = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: "")
        settings.target = self
        settings.tag = ItemTag.settings.rawValue
        menu.addItem(settings)

        let ignore = NSMenuItem(title: "Ignore Front App", action: #selector(toggleIgnore), keyEquivalent: "")
        ignore.target = self
        ignore.tag = ItemTag.ignore.rawValue
        menu.addItem(ignore)

        menu.addItem(.separator())

        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        login.target = self
        login.tag = ItemTag.launchAtLogin.rawValue
        menu.addItem(login)

        let logs = NSMenuItem(title: "Open Logs", action: #selector(openLogs), keyEquivalent: "")
        logs.target = self
        logs.tag = ItemTag.logs.rawValue
        menu.addItem(logs)

        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: "Quit \(AppIdentity.current.displayName)",
            action: #selector(quitApp),
            keyEquivalent: ""
        )
        quit.target = self
        quit.tag = ItemTag.quit.rawValue
        menu.addItem(quit)
    }

    private func makeActionItem(_ action: WindowAction) -> NSMenuItem {
        let item = NSMenuItem(title: action.displayName, action: #selector(execute(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = action.rawValue
        item.tag = ItemTag.action.rawValue
        applyImage(to: item, action: action)
        return item
    }

    private func applyImage(to item: NSMenuItem, action: WindowAction) {
        let portrait = (NSScreen.main?.frame.height ?? 0) > (NSScreen.main?.frame.width ?? 1)
        let image = PlacementIcon.image(for: action, rotateThirdsForPortrait: portrait)
        image.size = PlacementIcon.menuSize
        item.image = image
    }

    private func applyOpenState(to menu: NSMenu) {
        let hasFrontWindow = WindowCatalog.focusedWindowElement() != nil
        let hideDisplayTraversal = NSScreen.screens.count < 2 || runtime.settings.combinedDisplayMode
        walk(menu) { item in
            if item.tag == ItemTag.settings.rawValue {
                item.keyEquivalent = ","
                item.keyEquivalentModifierMask = .command
                return
            }
            if item.tag == ItemTag.quit.rawValue {
                item.keyEquivalent = "q"
                item.keyEquivalentModifierMask = .command
                return
            }
            if item.tag == ItemTag.ignore.rawValue {
                refreshIgnore(item)
                return
            }
            if item.tag == ItemTag.launchAtLogin.rawValue {
                item.state = runtime.launchAtLoginEnabled ? .on : .off
                return
            }
            guard let raw = item.representedObject as? String, let action = WindowAction(rawValue: raw) else {
                return
            }
            applyImage(to: item, action: action)
            MenuShortcut.apply(runtime.settings.shortcuts[action], to: item)
            if action == .nextDisplay || action == .previousDisplay {
                item.isHidden = hideDisplayTraversal
            }
            item.isEnabled = action.isMultiWindow ? runtime.accessibilityTrusted : hasFrontWindow
        }
    }

    private func clearShortcuts(in menu: NSMenu) {
        walk(menu) { item in
            MenuShortcut.clear(item)
            item.isEnabled = true
        }
    }

    private func refreshIgnore(_ item: NSMenuItem) {
        if let name = NSWorkspace.shared.frontmostApplication?.localizedName, !name.isEmpty {
            item.title = "Ignore \(name)"
            item.isHidden = false
        } else {
            item.title = "Ignore Front App"
            item.isHidden = true
        }
        item.state = runtime.isFrontmostIgnored ? .on : .off
    }

    private func walk(_ menu: NSMenu, _ body: (NSMenuItem) -> Void) {
        for item in menu.items {
            body(item)
            if let submenu = item.submenu {
                walk(submenu, body)
            }
        }
    }

    @objc private func execute(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let action = WindowAction(rawValue: raw) else { return }
        runtime.execute(action, source: .menu)
    }

    @objc private func showSettings() {
        onShowSettings()
    }

    @objc private func toggleIgnore() {
        runtime.toggleIgnoreFrontmostApp()
    }

    @objc private func toggleLaunchAtLogin() {
        runtime.setLaunchAtLogin(!runtime.launchAtLoginEnabled)
    }

    @objc private func openLogs() {
        AppLog.openLogsDirectory()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private struct CategoryMenu {
        let menu: NSMenu
        let category: WindowActionCategory
    }

    private enum ItemTag: Int {
        case settings = 1
        case ignore = 2
        case launchAtLogin = 3
        case logs = 4
        case quit = 5
        case action = 100
    }
}
