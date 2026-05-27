import AppKit
import SwiftUI

final class SettingsWindowController: NSObject {
    private let interceptor: GreenButtonInterceptor
    private let onChange: () -> Void

    private lazy var window: NSWindow = {
        let view = SettingsView(interceptor: interceptor, onChange: onChange)
        let hosting = NSHostingController(rootView: view)
        let w = NSWindow(contentViewController: hosting)
        w.styleMask = [.titled, .closable]
        w.title = "BetterGreenButton Settings"
        w.isReleasedWhenClosed = false
        w.setFrameAutosaveName("BetterGreenButton.Settings")
        w.center()
        return w
    }()

    init(interceptor: GreenButtonInterceptor, onChange: @escaping () -> Void) {
        self.interceptor = interceptor
        self.onChange = onChange
        super.init()
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
