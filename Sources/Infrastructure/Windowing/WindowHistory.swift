import CoreGraphics
import Domain
import Foundation

public final class WindowHistory: @unchecked Sendable {
    private let lock = NSLock()
    private var restoreRects: [UInt32: CGRect] = [:]
    private var lastActions: [UInt32: LastWindowAction] = [:]

    public init() {}

    public func restoreRect(for windowID: UInt32) -> CGRect? {
        lock.withLock { restoreRects[windowID] }
    }

    public func lastAction(for windowID: UInt32) -> LastWindowAction? {
        lock.withLock { lastActions[windowID] }
    }

    public func record(windowID: UInt32, original: CGRect, result: CGRect, action: WindowAction, subAction: String?) {
        lock.withLock {
            if restoreRects[windowID] == nil {
                restoreRects[windowID] = original
            }
            let previous = lastActions[windowID]
            let count = previous?.action == action ? (previous?.count ?? 0) + 1 : 1
            lastActions[windowID] = LastWindowAction(
                action: action,
                subAction: subAction,
                rect: RectSnapshot(x: result.minX, y: result.minY, width: result.width, height: result.height),
                count: count
            )
        }
    }

    public func restore(windowID: UInt32) -> CGRect? {
        lock.withLock {
            let rect = restoreRects.removeValue(forKey: windowID)
            lastActions.removeValue(forKey: windowID)
            return rect
        }
    }

    public func matchesLastRectangle(_ windowID: UInt32, frame: CGRect) -> Bool {
        lock.withLock {
            guard let last = lastActions[windowID] else { return false }
            return abs(last.rect.x - frame.minX) < 3
                && abs(last.rect.y - frame.minY) < 3
                && abs(last.rect.width - frame.width) < 3
                && abs(last.rect.height - frame.height) < 3
        }
    }
}
