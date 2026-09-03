import ApplicationServices
import CoreGraphics
import Darwin
import Domain
import Foundation

typealias CGSConnectionID = UInt32
typealias CGSSpaceID = UInt64

@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> CGSConnectionID

struct CGSWindowCaptureOptions: OptionSet {
    let rawValue: UInt32
    static let ignoreGlobalClipShape = CGSWindowCaptureOptions(rawValue: 1 << 11)
    static let nominalResolution = CGSWindowCaptureOptions(rawValue: 1 << 9)
}

@_silgen_name("CGSHWCaptureWindowList")
func CGSHWCaptureWindowList(
    _ cid: CGSConnectionID,
    _ windowList: UnsafeMutablePointer<CGWindowID>,
    _ windowCount: UInt32,
    _ options: CGSWindowCaptureOptions
) -> Unmanaged<CFArray>?

@_silgen_name("CGSCopyManagedDisplaySpaces")
func CGSCopyManagedDisplaySpaces(_ cid: CGSConnectionID) -> CFArray?

@_silgen_name("CGSCopyWindowsWithOptionsAndTags")
func CGSCopyWindowsWithOptionsAndTags(
    _ cid: CGSConnectionID,
    _ owner: Int,
    _ spaces: CFArray,
    _ options: Int,
    _ setTags: UnsafeMutablePointer<Int>,
    _ clearTags: UnsafeMutablePointer<Int>
) -> CFArray?

@_silgen_name("CGSCopySpacesForWindows")
func CGSCopySpacesForWindows(
    _ cid: CGSConnectionID,
    _ mask: Int,
    _ windows: CFArray
) -> CFArray?

@_silgen_name("_AXUIElementGetWindow")
func _AXUIElementGetWindow(_ element: AXUIElement, _ identifier: UnsafeMutablePointer<CGWindowID>) -> AXError

@_silgen_name("_AXUIElementCreateWithRemoteToken")
func _AXUIElementCreateWithRemoteToken(_ data: CFData) -> Unmanaged<AXUIElement>?

@_silgen_name("GetProcessForPID")
@discardableResult
func GetProcessForPID(_ pid: pid_t, _ psn: UnsafeMutablePointer<ProcessSerialNumber>) -> OSStatus

private typealias SLPSSetFrontProcessWithOptionsFn =
    @convention(c) (UnsafeMutablePointer<ProcessSerialNumber>, CGWindowID, UInt32) -> CGError
private typealias SLPSPostEventRecordToFn =
    @convention(c) (UnsafeMutablePointer<ProcessSerialNumber>, UnsafeMutablePointer<UInt8>) -> CGError

private let slpsSetFrontProcess: SLPSSetFrontProcessWithOptionsFn? = {
    guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "_SLPSSetFrontProcessWithOptions") else {
        return nil
    }
    return unsafeBitCast(symbol, to: SLPSSetFrontProcessWithOptionsFn.self)
}()

private let slpsPostEvent: SLPSPostEventRecordToFn? = {
    guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "SLPSPostEventRecordTo") else {
        return nil
    }
    return unsafeBitCast(symbol, to: SLPSPostEventRecordToFn.self)
}()

private typealias CopyDisplayForSpaceFn = @convention(c) (CGSConnectionID, CGSSpaceID) -> Unmanaged<CFString>?
private typealias SetCurrentSpaceFn = @convention(c) (CGSConnectionID, CFString, CGSSpaceID) -> CGError

private let copyDisplayForSpace: CopyDisplayForSpaceFn? = {
    let names = ["SLSCopyManagedDisplayForSpace", "CGSCopyManagedDisplayForSpace"]
    for name in names {
        if let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), name) {
            return unsafeBitCast(symbol, to: CopyDisplayForSpaceFn.self)
        }
    }
    return nil
}()

private let setCurrentSpace: SetCurrentSpaceFn? = {
    let names = ["SLSManagedDisplaySetCurrentSpace", "CGSManagedDisplaySetCurrentSpace"]
    for name in names {
        if let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), name) {
            return unsafeBitCast(symbol, to: SetCurrentSpaceFn.self)
        }
    }
    return nil
}()

enum SkyLight {
    static var connection: CGSConnectionID {
        CGSMainConnectionID()
    }

    static func currentSpaceIDs() -> (current: [UInt64], numbered: [UInt64: Int]) {
        guard let displays = CGSCopyManagedDisplaySpaces(connection) as? [[String: Any]] else {
            return ([], [:])
        }
        var current: [UInt64] = []
        var numbered: [UInt64: Int] = [:]
        var desktop = 1
        for display in displays {
            if let space = display["Current Space"] as? [String: Any],
               let identifier = space["id64"] as? UInt64
            {
                current.append(identifier)
            }
            if let spaces = display["Spaces"] as? [[String: Any]] {
                for space in spaces {
                    let type = space["type"] as? Int ?? 0
                    guard type == 0, let identifier = space["id64"] as? UInt64 else { continue }
                    numbered[identifier] = desktop
                    desktop += 1
                }
            }
        }
        return (current, numbered)
    }

    static func windowID(for element: AXUIElement) -> CGWindowID {
        var identifier: CGWindowID = 0
        let status = _AXUIElementGetWindow(element, &identifier)
        return status == .success ? identifier : 0
    }

    static func capture(_ windowID: CGWindowID) -> CGImage? {
        var identifier = windowID
        guard let array = CGSHWCaptureWindowList(
            connection,
            &identifier,
            1,
            [.ignoreGlobalClipShape, .nominalResolution]
        )?.takeRetainedValue() as? [CGImage]
        else {
            return nil
        }
        return array.first
    }

    static var canFocusOffSpaceWindows: Bool {
        slpsSetFrontProcess != nil && slpsPostEvent != nil
    }

    static func spaces(for windowID: CGWindowID) -> [UInt64] {
        guard windowID != 0 else { return [] }
        return (CGSCopySpacesForWindows(connection, 7, [windowID] as CFArray) as? [UInt64]) ?? []
    }

    static func focus(processID: pid_t, windowID: CGWindowID) -> Bool {
        guard canFocusOffSpaceWindows, windowID != 0 else { return false }
        var psn = ProcessSerialNumber()
        guard GetProcessForPID(processID, &psn) == noErr else { return false }
        let result = slpsSetFrontProcess?(&psn, windowID, 0x200)
        guard result == .success else { return false }
        makeKeyWindow(&psn, windowID)
        return true
    }

    /// Native fullscreen windows each own a Space. SLPS usually switches as a
    /// side effect; this is the fallback when the process is already frontmost.
    @discardableResult
    static func revealSpace(of windowID: CGWindowID) -> Bool {
        let windowSpaces = spaces(for: windowID)
        let current = currentSpaceIDs().current
        if windowSpaces.isEmpty || windowSpaces.contains(where: { current.contains($0) }) {
            return true
        }
        guard let space = windowSpaces.first else { return false }
        if let copyDisplayForSpace,
           let unmanaged = copyDisplayForSpace(connection, space)
        {
            let display = unmanaged.takeRetainedValue()
            return setCurrentSpace?(connection, display, space) == .success
        }
        guard let displays = CGSCopyManagedDisplaySpaces(connection) as? [[String: Any]] else {
            return false
        }
        for display in displays {
            let identifiers = spaceIdentifiers(in: display)
            guard identifiers.contains(space),
                  let uuid = display["Display Identifier"] as? String
            else { continue }
            return setCurrentSpace?(connection, uuid as CFString, space) == .success
        }
        return false
    }

    private static func spaceIdentifiers(in display: [String: Any]) -> [UInt64] {
        var identifiers: [UInt64] = []
        if let current = display["Current Space"] as? [String: Any],
           let identifier = current["id64"] as? UInt64
        {
            identifiers.append(identifier)
        }
        if let spaces = display["Spaces"] as? [[String: Any]] {
            for space in spaces {
                if let identifier = space["id64"] as? UInt64 {
                    identifiers.append(identifier)
                }
            }
        }
        return identifiers
    }

    static func elementsOnOtherSpaces(processID: pid_t) -> [AXUIElement] {
        var token = Data(count: 20)
        token.replaceSubrange(0..<4, with: withUnsafeBytes(of: processID) { Data($0) })
        token.replaceSubrange(4..<8, with: withUnsafeBytes(of: Int32(0)) { Data($0) })
        token.replaceSubrange(8..<12, with: withUnsafeBytes(of: Int32(0x636F_636F)) { Data($0) })
        var elements: [AXUIElement] = []
        let deadline = ProcessInfo.processInfo.systemUptime + 0.1
        for identifier: UInt64 in 0..<1000 {
            token.replaceSubrange(12..<20, with: withUnsafeBytes(of: identifier) { Data($0) })
            if let element = _AXUIElementCreateWithRemoteToken(token as CFData)?.takeRetainedValue() {
                AXUIElementSetMessagingTimeout(element, 0.1)
                var subrole: AnyObject?
                if AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subrole) == .success,
                   WindowClassification.acceptsWindowSubrole(subrole as? String)
                {
                    elements.append(element)
                }
            }
            if ProcessInfo.processInfo.systemUptime > deadline { break }
        }
        return elements
    }

    private static func makeKeyWindow(_ psn: inout ProcessSerialNumber, _ windowID: CGWindowID) {
        var identifier = windowID
        var bytes = [UInt8](repeating: 0, count: 0xF8)
        bytes[0x04] = 0xF8
        bytes[0x3A] = 0x10
        memcpy(&bytes[0x3C], &identifier, MemoryLayout<UInt32>.size)
        memset(&bytes[0x20], 0xFF, 0x10)
        bytes[0x08] = 0x01
        _ = slpsPostEvent?(&psn, &bytes)
        bytes[0x08] = 0x02
        _ = slpsPostEvent?(&psn, &bytes)
    }
}
