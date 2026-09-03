import AppKit
import Carbon
import Domain
import Foundation

@MainActor
public final class HotkeyCenter: @unchecked Sendable {
    public var onSameAppSwitcher: (() -> Void)?
    public var onAppSwitcher: (() -> Void)?
    public var onWindowAction: ((WindowAction) -> Void)?
    public var onWindowActionCycle: (([WindowAction]) -> Void)?
    public var onAppSwitcherRepeat: ((Bool) -> Void)?
    public var onAppSwitcherReleased: (() -> Void)?

    private var handler: EventHandlerRef?
    private var refs: [UInt32: EventHotKeyRef] = [:]
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let interceptState = InterceptState()
    private var shortcutIDs: [UInt32: [WindowAction]] = [:]
    private var lastSettings: AppSettings?
    private var includeSwitcher = true
    private var includePlacement = true

    public init() {}

    public func register(
        settings: AppSettings,
        includeSwitcher: Bool = true,
        includePlacement: Bool = true
    ) {
        lastSettings = settings
        self.includeSwitcher = includeSwitcher
        self.includePlacement = includePlacement
        installHandlerIfNeeded()
        syncSwitcherCarbon(settings: settings, enabled: includeSwitcher)
        syncEventTap(settings: settings, enabled: includeSwitcher)
        syncPlacement(settings: settings, enabled: includePlacement)
    }

    public func setPlacementEnabled(_ enabled: Bool) {
        includePlacement = enabled
        guard let settings = lastSettings else { return }
        syncPlacement(settings: settings, enabled: enabled)
    }

    public func unregister() {
        unregisterIDs(Array(refs.keys))
        shortcutIDs.removeAll()
        stopEventTap()
        if let handler {
            RemoveEventHandler(handler)
            self.handler = nil
        }
    }

    public func setAppSwitcherVisible(_ visible: Bool) {
        interceptState.setAppSwitcherOpen(visible)
    }

    public func setSameAppSwitcherVisible(_ visible: Bool) {
        interceptState.setSameAppOpen(visible)
    }

    private func syncSwitcherCarbon(settings: AppSettings, enabled: Bool) {
        unregisterIDs([1, 2])
        guard enabled else { return }
        registerSwitcher(
            id: 1,
            signature: 0x4453_3248,
            keyCode: settings.triggerKey.keyCode,
            modifiers: settings.modifierKey.carbonModifier
        )
        if settings.appSwitcherEnabled {
            let usesSystemTab = settings.appSwitcherModifierKey == .command
                && settings.appSwitcherTriggerKey == .tab
            if !usesSystemTab {
                registerSwitcher(
                    id: 2,
                    signature: 0x4354_3248,
                    keyCode: settings.appSwitcherTriggerKey.keyCode,
                    modifiers: settings.appSwitcherModifierKey.carbonModifier
                )
            }
        }
    }

    private func syncEventTap(settings: AppSettings, enabled: Bool) {
        let usesSystemTab = settings.appSwitcherEnabled
            && settings.appSwitcherModifierKey == .command
            && settings.appSwitcherTriggerKey == .tab
        interceptState.configure(
            enabled: enabled && usesSystemTab,
            modifier: Self.cgFlags(for: settings.appSwitcherModifierKey),
            triggerKeyCode: settings.appSwitcherTriggerKey.keyCode
        )
        if enabled, usesSystemTab {
            if eventTap == nil {
                startEventTap()
            }
        } else {
            stopEventTap()
        }
    }

    private func syncPlacement(settings: AppSettings, enabled: Bool) {
        unregisterIDs(refs.keys.filter { $0 >= 100 })
        shortcutIDs.removeAll()
        guard enabled else { return }
        var nextID: UInt32 = 100
        for group in ShortcutCycle.groups(from: settings.shortcuts) {
            registerChord(id: nextID, chord: group.chord)
            shortcutIDs[nextID] = group.actions
            nextID += 1
        }
    }

    private func unregisterIDs(_ ids: [UInt32]) {
        for id in ids {
            if let ref = refs.removeValue(forKey: id) {
                UnregisterEventHotKey(ref)
            }
        }
    }

    private func installHandlerIfNeeded() {
        guard handler == nil else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        let result = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData, let event else { return OSStatus(eventNotHandledErr) }
                let center = Unmanaged<HotkeyCenter>.fromOpaque(userData).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                if status == noErr {
                    Task { @MainActor in
                        center.handle(hotKeyID)
                    }
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &handler
        )
        if result != noErr {
            AppLog.hotkeys.error("InstallEventHandler failed: \(result)")
        }
    }

    private func registerSwitcher(id: UInt32, signature: OSType, keyCode: UInt32, modifiers: UInt32) {
        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: id)
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
        if status == noErr, let ref {
            refs[id] = ref
        } else {
            AppLog.hotkeys.error("RegisterEventHotKey \(id) failed: \(status)")
        }
    }

    private func registerChord(id: UInt32, chord: KeyChord) {
        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: 0x4543_524E, id: id)
        let modifiers = carbonModifiers(from: chord.modifierFlags)
        let status = RegisterEventHotKey(UInt32(chord.keyCode), modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
        if status == noErr, let ref {
            refs[id] = ref
        }
    }

    private func carbonModifiers(from flags: UInt) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags & (1 << 20) != 0 { modifiers |= UInt32(cmdKey) }
        if flags & (1 << 19) != 0 { modifiers |= UInt32(optionKey) }
        if flags & (1 << 18) != 0 { modifiers |= UInt32(controlKey) }
        if flags & (1 << 17) != 0 { modifiers |= UInt32(shiftKey) }
        if flags & (1 << 23) != 0 { modifiers |= UInt32(kEventKeyModifierFnMask) }
        return modifiers
    }

    private func handle(_ hotKeyID: EventHotKeyID) {
        switch hotKeyID.id {
        case 1:
            onSameAppSwitcher?()
        case 2:
            onAppSwitcher?()
        default:
            if let actions = shortcutIDs[hotKeyID.id] {
                if actions.count == 1 {
                    onWindowAction?(actions[0])
                } else {
                    onWindowActionCycle?(actions)
                }
            }
        }
    }

    private func startEventTap() {
        stopEventTap()
        let mask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, userData in
                guard let userData else { return Unmanaged.passUnretained(event) }
                let center = Unmanaged<HotkeyCenter>.fromOpaque(userData).takeUnretainedValue()
                return center.handleTap(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        guard let eventTap else {
            AppLog.hotkeys.error("Failed to create Command-Tab event tap")
            return
        }
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        CGEvent.tapEnable(tap: eventTap, enable: true)
        interceptState.setPort(eventTap)
        AppLog.hotkeys.info("Command-Tab event tap started")
    }

    private func stopEventTap() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        interceptState.setPort(nil)
    }

    nonisolated private func handleTap(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let port = interceptState.port {
                CGEvent.tapEnable(tap: port, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        guard interceptState.tapEnabled else {
            return Unmanaged.passUnretained(event)
        }
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        let modifier = interceptState.modifier
        let trigger = interceptState.triggerKeyCode
        if type == .keyDown, keyCode == trigger, flags.contains(modifier) {
            let shift = flags.contains(.maskShift)
            if interceptState.sameAppOpen {
                interceptState.setSameAppOpen(false)
                interceptState.setAppSwitcherOpen(true)
                Task { @MainActor in
                    onAppSwitcher?()
                }
                return nil
            }
            let repeating = interceptState.appSwitcherOpen
            if !repeating {
                interceptState.setAppSwitcherOpen(true)
            }
            Task { @MainActor in
                if repeating {
                    onAppSwitcherRepeat?(shift)
                } else {
                    onAppSwitcher?()
                }
            }
            return nil
        }
        if type == .flagsChanged, interceptState.appSwitcherOpen, !flags.contains(modifier) {
            interceptState.setAppSwitcherOpen(false)
            Task { @MainActor in
                onAppSwitcherReleased?()
            }
        }
        return Unmanaged.passUnretained(event)
    }

    private static func cgFlags(for key: ModifierKey) -> CGEventFlags {
        switch key {
        case .command: .maskCommand
        case .option: .maskAlternate
        case .control: .maskControl
        case .function: .maskSecondaryFn
        }
    }
}

private final class InterceptState: @unchecked Sendable {
    private let lock = NSLock()
    private var tapEnabledValue = false
    private var appSwitcherOpenValue = false
    private var sameAppOpenValue = false
    private var modifierValue: CGEventFlags = .maskCommand
    private var triggerKeyCodeValue: Int64 = 48
    private var portValue: CFMachPort?

    var tapEnabled: Bool { lock.withLock { tapEnabledValue } }
    var appSwitcherOpen: Bool { lock.withLock { appSwitcherOpenValue } }
    var sameAppOpen: Bool { lock.withLock { sameAppOpenValue } }
    var modifier: CGEventFlags { lock.withLock { modifierValue } }
    var triggerKeyCode: Int64 { lock.withLock { triggerKeyCodeValue } }
    var port: CFMachPort? { lock.withLock { portValue } }

    func configure(enabled: Bool, modifier: CGEventFlags, triggerKeyCode: UInt32) {
        lock.withLock {
            tapEnabledValue = enabled
            modifierValue = modifier
            triggerKeyCodeValue = Int64(triggerKeyCode)
        }
    }

    func setAppSwitcherOpen(_ value: Bool) {
        lock.withLock { appSwitcherOpenValue = value }
    }

    func setSameAppOpen(_ value: Bool) {
        lock.withLock { sameAppOpenValue = value }
    }

    func setPort(_ port: CFMachPort?) {
        lock.withLock { portValue = port }
    }
}
