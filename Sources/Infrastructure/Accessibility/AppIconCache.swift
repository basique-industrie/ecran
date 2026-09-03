import AppKit
import Foundation

public final class AppIconCache: @unchecked Sendable {
    public static let shared = AppIconCache()

    private let lock = NSLock()
    private var icons: [pid_t: NSImage] = [:]

    public func icon(for processID: pid_t) -> NSImage? {
        lock.lock()
        if let cached = icons[processID] {
            lock.unlock()
            return cached
        }
        lock.unlock()
        guard let image = NSRunningApplication(processIdentifier: processID)?.icon else { return nil }
        let sized = NSImage(size: NSSize(width: 128, height: 128), flipped: false) { rect in
            image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
            return true
        }
        lock.withLock {
            if icons.count > 60 {
                icons.removeAll()
            }
            icons[processID] = sized
        }
        return sized
    }

    public func evict(keeping processIDs: Set<pid_t>) {
        lock.withLock {
            icons = icons.filter { processIDs.contains($0.key) }
        }
    }

    public func clear() {
        lock.withLock { icons.removeAll() }
    }
}
