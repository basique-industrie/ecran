import AppKit
import ApplicationServices
import Domain
import Foundation

public enum WindowCatalog {
    public static func sameAppWindows(settings: AppSettings, excludingBundleID: String?) -> [WindowRecord] {
        guard let app = targetApp(excluding: excludingBundleID) else { return [] }
        return windows(
            for: app,
            settings: settings,
            excludingBundleID: excludingBundleID
        )
    }

    public static func runningRegularApps(settings: AppSettings, excludingBundleID: String?) -> [AppRecord] {
        _ = settings
        let zOrder = onScreenZOrder()
        var chosen: [String: NSRunningApplication] = [:]
        var rank: [String: Int] = [:]
        for app in NSWorkspace.shared.runningApplications {
            guard AppSwitcherListing.includes(
                isRegular: app.activationPolicy == .regular,
                bundleID: app.bundleIdentifier,
                excludingBundleID: excludingBundleID
            ), let bundleID = app.bundleIdentifier else { continue }
            let z = zOrder[app.processIdentifier] ?? Int.max
            if let existing = chosen[bundleID] {
                let keepIncoming = AppSwitcherListing.prefersIncoming(
                    existingActive: existing.isActive,
                    existingZOrder: rank[bundleID] ?? Int.max,
                    incomingActive: app.isActive,
                    incomingZOrder: z
                )
                if !keepIncoming { continue }
            }
            chosen[bundleID] = app
            rank[bundleID] = z
        }
        return chosen.values
            .map { app in
                AppRecord(
                    bundleID: app.bundleIdentifier ?? "",
                    processID: app.processIdentifier,
                    appName: app.localizedName ?? "Unknown",
                    windowCount: fastWindowCount(processID: app.processIdentifier),
                    isActive: app.isActive
                )
            }
            .sorted { lhs, rhs in
                let left = zOrder[lhs.processID] ?? Int.max
                let right = zOrder[rhs.processID] ?? Int.max
                if left != right { return left < right }
                return lhs.appName.localizedCaseInsensitiveCompare(rhs.appName) == .orderedAscending
            }
    }

    public static func acceptsWindowSubrole(_ subrole: String?) -> Bool {
        WindowClassification.acceptsWindowSubrole(subrole)
    }

    public static func frontmostRegularApp(excludingBundleID: String?) -> NSRunningApplication? {
        targetApp(excluding: excludingBundleID)
    }

    public static func windows(
        for app: NSRunningApplication,
        settings: AppSettings,
        excludingBundleID: String?
    ) -> [WindowRecord] {
        let application = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(application, 0.25)
        var value: AnyObject?
        AXUIElementCopyAttributeValue(application, kAXWindowsAttribute as CFString, &value)
        var elements = (value as? [AXUIElement]) ?? []
        if settings.showWindowsFromAllSpaces {
            elements.append(contentsOf: SkyLight.elementsOnOtherSpaces(processID: app.processIdentifier))
        }
        let spaces = SkyLight.currentSpaceIDs()
        let layers = windowLayers()
        var seen: Set<CGWindowID> = []
        var records: [WindowRecord] = []
        for element in elements {
            let subrole = stringAttribute(element, kAXSubroleAttribute)
            guard WindowClassification.acceptsWindowSubrole(subrole) else { continue }
            let title = stringAttribute(element, kAXTitleAttribute) ?? ""
            let minimized = boolAttribute(element, kAXMinimizedAttribute)
            let windowID = SkyLight.windowID(for: element)
            if windowID != 0, !seen.insert(windowID).inserted { continue }
            let layer = layers[windowID] ?? 0
            let bundleID = app.bundleIdentifier ?? ""
            guard WindowClassification.isValidWindowLayer(layer, forBundleID: bundleID) else { continue }
            let windowSpaces = SkyLight.spaces(for: windowID)
            let spaceIndex = spaceIndex(for: windowID, current: spaces.current, numbered: spaces.numbered)
            let onOtherSpace = SpaceMembership.isOnOtherSpace(
                windowSpaces: windowSpaces,
                currentSpaces: spaces.current,
                isMinimized: minimized
            )
            if !settings.showWindowsFromAllSpaces, onOtherSpace, !minimized {
                continue
            }
            let project = TitleExtractor.extract(
                title,
                bundleID: bundleID,
                appConfigs: settings.appTitleConfigs,
                defaultStrategy: settings.defaultTitleStrategy,
                defaultSeparator: settings.defaultCustomSeparator
            )
            records.append(
                WindowRecord(
                    windowID: windowID,
                    title: title,
                    projectName: project,
                    appName: app.localizedName ?? "Unknown",
                    bundleID: bundleID,
                    processID: app.processIdentifier,
                    isMinimized: minimized,
                    isOnOtherSpace: onOtherSpace,
                    spaceIndex: spaceIndex,
                    layer: layer
                )
            )
        }
        return records.sorted { lhs, rhs in
            let left = (lhs.isMinimized ? 2 : lhs.isOnOtherSpace ? 1 : 0, lhs.spaceIndex, lhs.windowID)
            let right = (rhs.isMinimized ? 2 : rhs.isOnOtherSpace ? 1 : 0, rhs.spaceIndex, rhs.windowID)
            return left < right
        }
    }

    public static func activate(window: WindowRecord) {
        if window.isOnOtherSpace {
            SkyLight.revealSpace(of: window.windowID)
        }
        let match = element(for: window)
        if window.isMinimized, let match {
            AXUIElementSetAttributeValue(match, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
            AXUIElementPerformAction(match, kAXRaiseAction as CFString)
        }
        if window.windowID != 0, SkyLight.focus(processID: window.processID, windowID: window.windowID) {
            if let match {
                AXUIElementPerformAction(match, kAXRaiseAction as CFString)
            }
            return
        }
        if let app = NSRunningApplication(processIdentifier: window.processID) {
            app.activate()
        }
        if window.isOnOtherSpace {
            SkyLight.revealSpace(of: window.windowID)
        }
        if let match {
            AXUIElementSetAttributeValue(match, kAXMainAttribute as CFString, kCFBooleanTrue)
            AXUIElementPerformAction(match, kAXRaiseAction as CFString)
            AXUIElementSetAttributeValue(match, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        }
    }

    private static func element(for window: WindowRecord) -> AXUIElement? {
        let application = AXUIElementCreateApplication(window.processID)
        var value: AnyObject?
        AXUIElementCopyAttributeValue(application, kAXWindowsAttribute as CFString, &value)
        if let match = (value as? [AXUIElement])?.first(where: { SkyLight.windowID(for: $0) == window.windowID }) {
            return match
        }
        guard window.windowID != 0 else { return nil }
        return SkyLight.elementsOnOtherSpaces(processID: window.processID)
            .first { SkyLight.windowID(for: $0) == window.windowID }
    }

    public static func activate(app: AppRecord) {
        NSRunningApplication(processIdentifier: app.processID)?
            .activate(options: [.activateAllWindows])
    }

    public static func windowID(for element: AXUIElement) -> CGWindowID {
        SkyLight.windowID(for: element)
    }

    public static func focusedWindowElement() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let application = AXUIElementCreateApplication(app.processIdentifier)
        var value: AnyObject?
        let status = AXUIElementCopyAttributeValue(application, kAXFocusedWindowAttribute as CFString, &value)
        guard status == .success else { return nil }
        return axElement(value)
    }

    /// Window under the cursor. No focused-window fallback: that snaps the
    /// wrong window when hit-test fails during an accessory-app drag.
    public static func windowForDrag(at point: CGPoint) -> AXUIElement? {
        guard let hit = element(at: point) else { return nil }
        return windowElement(containing: hit)
    }

    public static func isSnappableWindow(_ element: AXUIElement) -> Bool {
        WindowClassification.acceptsWindowSubrole(stringAttribute(element, kAXSubroleAttribute))
    }

    public static func element(at point: CGPoint) -> AXUIElement? {
        let system = AXUIElementCreateSystemWide()
        var value: AXUIElement?
        let status = AXUIElementCopyElementAtPosition(system, Float(point.x), Float(point.y), &value)
        guard status == .success else { return nil }
        return value
    }

    public static func windowElement(containing element: AXUIElement) -> AXUIElement? {
        var current: AXUIElement? = element
        while let examined = current {
            if stringAttribute(examined, kAXRoleAttribute) == (kAXWindowRole as String) {
                return examined
            }
            var parent: AnyObject?
            guard AXUIElementCopyAttributeValue(examined, kAXParentAttribute as CFString, &parent) == .success else {
                return nil
            }
            current = axElement(parent)
        }
        return nil
    }

    public static func isFullScreenButton(_ element: AXUIElement) -> Bool {
        stringAttribute(element, kAXSubroleAttribute) == (kAXFullScreenButtonSubrole as String)
            || stringAttribute(element, kAXSubroleAttribute) == "AXFullScreenButton"
    }

    public static func titleBarFrame(of window: AXUIElement) -> CGRect? {
        guard let windowFrame = frame(of: window) else { return nil }
        var close: AnyObject?
        if AXUIElementCopyAttributeValue(window, kAXCloseButtonAttribute as CFString, &close) == .success,
           let button = axElement(close),
           let closeFrame = frame(of: button)
        {
            let height = max(22, 2 * (closeFrame.minY - windowFrame.minY) + closeFrame.height)
            return CGRect(x: windowFrame.minX, y: windowFrame.minY, width: windowFrame.width, height: height)
        }
        return CGRect(x: windowFrame.minX, y: windowFrame.minY, width: windowFrame.width, height: 28)
    }

    public static func frame(of element: AXUIElement) -> CGRect? {
        var positionValue: AnyObject?
        var sizeValue: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue)
        AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue)
        guard let position = axValue(positionValue), let size = axValue(sizeValue) else { return nil }
        var point = CGPoint.zero
        var dimensions = CGSize.zero
        AXValueGetValue(position, .cgPoint, &point)
        AXValueGetValue(size, .cgSize, &dimensions)
        return CGRect(origin: point, size: dimensions)
    }

    @MainActor
    public static func setFrame(_ rect: CGRect, of element: AXUIElement, adjustSizeFirst: Bool = true) {
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        let application = AXUIElementCreateApplication(pid)
        var enhanced: AnyObject?
        let hadEnhanced = AXUIElementCopyAttributeValue(
            application,
            "AXEnhancedUserInterface" as CFString,
            &enhanced
        ) == .success && (enhanced as? Bool == true)
        if hadEnhanced {
            AXUIElementSetAttributeValue(application, "AXEnhancedUserInterface" as CFString, kCFBooleanFalse)
        }
        var origin = rect.origin
        var size = rect.size
        let position = AXValueCreate(.cgPoint, &origin)
        let dimensions = AXValueCreate(.cgSize, &size)
        if adjustSizeFirst, let dimensions {
            AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, dimensions)
        }
        if let position {
            AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, position)
        }
        if let dimensions {
            AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, dimensions)
        }
        if hadEnhanced {
            AXUIElementSetAttributeValue(application, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
        }
    }

    public static func bundleID(of element: AXUIElement) -> String? {
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        return NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
    }

    public static func onScreenWindows(
        settings: AppSettings,
        excludingBundleID: String?,
        processID: pid_t? = nil
    ) -> [(record: WindowRecord, element: AXUIElement, frame: CGRect)] {
        _ = settings
        let zOrder = onScreenWindowRanks()
        guard !zOrder.isEmpty else { return [] }
        let layers = windowLayers()
        var results: [(record: WindowRecord, element: AXUIElement, frame: CGRect)] = []
        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular else { continue }
            if let processID, app.processIdentifier != processID { continue }
            if let excludingBundleID, app.bundleIdentifier == excludingBundleID { continue }
            let application = AXUIElementCreateApplication(app.processIdentifier)
            AXUIElementSetMessagingTimeout(application, 0.25)
            var value: AnyObject?
            AXUIElementCopyAttributeValue(application, kAXWindowsAttribute as CFString, &value)
            guard let elements = value as? [AXUIElement] else { continue }
            let bundleID = app.bundleIdentifier ?? ""
            for element in elements {
                let subrole = stringAttribute(element, kAXSubroleAttribute)
                guard WindowClassification.acceptsWindowSubrole(subrole) else { continue }
                let windowID = SkyLight.windowID(for: element)
                guard windowID != 0, zOrder[windowID] != nil else { continue }
                guard WindowClassification.isValidWindowLayer(layers[windowID] ?? 0, forBundleID: bundleID) else {
                    continue
                }
                guard let frame = frame(of: element) else { continue }
                let minimized = boolAttribute(element, kAXMinimizedAttribute)
                if minimized { continue }
                let title = stringAttribute(element, kAXTitleAttribute) ?? ""
                let record = WindowRecord(
                    windowID: windowID,
                    title: title,
                    projectName: title,
                    appName: app.localizedName ?? "Unknown",
                    bundleID: bundleID,
                    processID: app.processIdentifier,
                    isMinimized: false,
                    isOnOtherSpace: false,
                    spaceIndex: 0,
                    layer: layers[windowID] ?? 0
                )
                results.append((record, element, frame))
            }
        }
        return results.sorted {
            (zOrder[$0.record.windowID] ?? Int.max) < (zOrder[$1.record.windowID] ?? Int.max)
        }
    }

    public static func previewImage(for windowID: CGWindowID) -> NSImage? {
        guard windowID != 0, let image = SkyLight.capture(windowID) else { return nil }
        return NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
    }

    public static func appIcon(for processID: pid_t) -> NSImage? {
        AppIconCache.shared.icon(for: processID)
    }

    private static func fastWindowCount(processID: pid_t) -> Int {
        let application = AXUIElementCreateApplication(processID)
        AXUIElementSetMessagingTimeout(application, 0.2)
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(application, kAXWindowsAttribute as CFString, &value) == .success,
              let elements = value as? [AXUIElement]
        else {
            return 0
        }
        return elements.filter { WindowClassification.acceptsWindowSubrole(stringAttribute($0, kAXSubroleAttribute)) }.count
    }

    private static func targetApp(excluding bundleID: String?) -> NSRunningApplication? {
        if let active = NSWorkspace.shared.frontmostApplication,
           active.activationPolicy == .regular,
           active.bundleIdentifier != bundleID
        {
            return active
        }
        return NSWorkspace.shared.runningApplications.first {
            $0.activationPolicy == .regular && $0.bundleIdentifier != bundleID && $0.isActive
        }
    }

    private static func axElement(_ object: AnyObject?) -> AXUIElement? {
        guard let object else { return nil }
        let value = object as CFTypeRef
        guard CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        // Type ID already matched; this is not a blind cast.
        return (object as! AXUIElement)
    }

    private static func axValue(_ object: AnyObject?) -> AXValue? {
        guard let object else { return nil }
        let value = object as CFTypeRef
        guard CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        return (object as! AXValue)
    }

    private static func stringAttribute(_ element: AXUIElement, _ name: String) -> String? {
        var value: AnyObject?
        let status = AXUIElementCopyAttributeValue(element, name as CFString, &value)
        guard status == .success else { return nil }
        return value as? String
    }

    private static func boolAttribute(_ element: AXUIElement, _ name: String) -> Bool {
        var value: AnyObject?
        let status = AXUIElementCopyAttributeValue(element, name as CFString, &value)
        guard status == .success else { return false }
        return (value as? Bool) ?? false
    }

    private static func spaceIndex(
        for windowID: CGWindowID,
        current: [UInt64],
        numbered: [UInt64: Int]
    ) -> Int {
        guard windowID != 0 else { return 0 }
        guard let spaces = CGSCopySpacesForWindows(
            SkyLight.connection,
            7,
            [windowID] as CFArray
        ) as? [UInt64]
        else {
            return 0
        }
        if let match = spaces.first(where: { numbered[$0] != nil }) {
            return numbered[match] ?? 0
        }
        if spaces.contains(where: { current.contains($0) }) {
            return 0
        }
        return numbered[spaces.first ?? 0] ?? 0
    }

    private static func onScreenWindowRanks() -> [CGWindowID: Int] {
        guard let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
            as? [[String: Any]]
        else {
            return [:]
        }
        var order: [CGWindowID: Int] = [:]
        for (index, window) in info.enumerated() {
            guard let identifier = window[kCGWindowNumber as String] as? CGWindowID else { continue }
            if order[identifier] == nil {
                order[identifier] = index
            }
        }
        return order
    }

    private static func onScreenZOrder() -> [pid_t: Int] {
        guard let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
            as? [[String: Any]]
        else {
            return [:]
        }
        var order: [pid_t: Int] = [:]
        for (index, window) in info.enumerated() {
            guard let pid = window[kCGWindowOwnerPID as String] as? pid_t else { continue }
            if order[pid] == nil {
                order[pid] = index
            }
        }
        return order
    }

    private static func windowLayers() -> [CGWindowID: Int] {
        guard let info = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID)
            as? [[String: Any]]
        else {
            return [:]
        }
        var layers: [CGWindowID: Int] = [:]
        for window in info {
            guard let identifier = window[kCGWindowNumber as String] as? CGWindowID,
                  let layer = window[kCGWindowLayer as String] as? Int
            else { continue }
            layers[identifier] = layer
        }
        return layers
    }
}
