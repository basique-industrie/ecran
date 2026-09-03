import AppKit
import Infrastructure
import SwiftUI

enum SettingsWindowMetrics {
    static let minSize = NSSize(width: 860, height: 600)
    static let defaultSize = NSSize(width: 900, height: 680)
}

@MainActor
final class SettingsController {
    private var window: NSWindow?
    private let runtime: EcranRuntime
    private let navigation = SettingsNavigation()
    private var storeErrorObserver: NSObjectProtocol?

    init(runtime: EcranRuntime) {
        self.runtime = runtime
        storeErrorObserver = NotificationCenter.default.addObserver(
            forName: .settingsStoreError,
            object: nil,
            queue: .main
        ) { notification in
            let message = notification.userInfo?["message"] as? String
                ?? "Ecran could not save settings."
            MainThreadHop.run {
                SettingsAlert.show(title: "Settings could not be saved", message: message)
            }
        }
    }

    func invalidate() {
        if let storeErrorObserver {
            NotificationCenter.default.removeObserver(storeErrorObserver)
        }
        storeErrorObserver = nil
    }

    func show() {
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(origin: .zero, size: SettingsWindowMetrics.defaultSize),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Settings"
            window.level = .normal
            window.isOpaque = true
            window.backgroundColor = EcranChrome.popoverNSColor
            window.titlebarAppearsTransparent = false
            window.appearance = NSAppearance(named: .darkAqua)
            window.isReleasedWhenClosed = false
            window.hidesOnDeactivate = false
            window.hasShadow = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.minSize = SettingsWindowMetrics.minSize
            let hosting = NSHostingView(
                rootView: SettingsView(runtime: runtime, navigation: navigation)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
            hosting.setContentHuggingPriority(.defaultLow, for: .horizontal)
            hosting.setContentHuggingPriority(.defaultLow, for: .vertical)
            window.contentView = hosting
            let tabs = SettingsTabHostingView(rootView: SettingsTabBar(navigation: navigation))
            tabs.frame = NSRect(x: 0, y: 0, width: 900, height: SettingsTabHostingView.barHeight)
            let accessory = NSTitlebarAccessoryViewController()
            accessory.layoutAttribute = .bottom
            accessory.view = tabs
            window.addTitlebarAccessoryViewController(accessory)
            self.window = window
        }
        guard let window else { return }
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        if !window.isVisible {
            window.center()
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private final class SettingsTabHostingView: NSHostingView<SettingsTabBar> {
    static let barHeight: CGFloat = 52

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: Self.barHeight)
    }

    override func layout() {
        super.layout()
        if abs(frame.height - Self.barHeight) > 0.5 {
            frame.size.height = Self.barHeight
        }
    }
}
