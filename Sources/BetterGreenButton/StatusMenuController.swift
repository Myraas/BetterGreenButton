import AppKit
import ApplicationServices

final class StatusMenuController: NSObject, NSMenuDelegate {
    private let interceptor: GreenButtonInterceptor
    private let statusItem: NSStatusItem

    private let enabledItem = NSMenuItem(title: "Enabled", action: nil, keyEquivalent: "")
    private let autoHideItem = NSMenuItem(
        title: "Auto-hide menu icon",
        action: nil,
        keyEquivalent: ""
    )
    private let loginItem = NSMenuItem(
        title: "Start at Login",
        action: nil,
        keyEquivalent: ""
    )
    private let accessibilityItem = NSMenuItem(
        title: "Grant Accessibility Permission…",
        action: nil,
        keyEquivalent: ""
    )
    private let coffeeItem = NSMenuItem(
        title: "Buy Me a Coffee",
        action: nil,
        keyEquivalent: ""
    )

    private var permissionTimer: Timer?
    private var autoHideTimer: Timer?

    private static let autoHideDelay: TimeInterval = 10
    private static let enabledKey = "BetterGreenButton.enabled"
    private static let autoHideKey = "BetterGreenButton.autoHide"
    private static let everTrustedKey = "BetterGreenButton.everTrusted"

    private var interceptEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: Self.enabledKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: Self.enabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: Self.enabledKey) }
    }

    private var autoHideOn: Bool {
        get { UserDefaults.standard.bool(forKey: Self.autoHideKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.autoHideKey) }
    }

    init(interceptor: GreenButtonInterceptor) {
        self.interceptor = interceptor
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if UserDefaults.standard.bool(forKey: Self.everTrustedKey) && !AXIsProcessTrusted() {
            Self.runTccutilReset()
        }

        if let button = statusItem.button {
            let custom = Bundle.main.image(forResource: "menu-icon")
            let image = custom ?? NSImage(
                systemSymbolName: "arrow.up.left.and.arrow.down.right",
                accessibilityDescription: nil
            )
            image?.isTemplate = true
            button.image = image
        }

        let menu = NSMenu()
        menu.delegate = self

        enabledItem.target = self
        enabledItem.action = #selector(toggleEnabled)
        menu.addItem(enabledItem)

        menu.addItem(.separator())

        autoHideItem.target = self
        autoHideItem.action = #selector(toggleAutoHide)
        menu.addItem(autoHideItem)

        loginItem.target = self
        loginItem.action = #selector(toggleLoginItem)
        menu.addItem(loginItem)

        menu.addItem(.separator())

        accessibilityItem.target = self
        accessibilityItem.action = #selector(requestAccessibility)
        menu.addItem(accessibilityItem)

        menu.addItem(.separator())

        coffeeItem.target = self
        coffeeItem.action = #selector(openCoffeeLink)
        menu.addItem(coffeeItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit BetterGreenButton",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        statusItem.menu = menu

        interceptor.isEnabled = interceptEnabled

        refreshState()
        if !AXIsProcessTrusted() { startPermissionPolling() }
        statusItem.isVisible = true
        scheduleAutoHide()
    }

    func showIcon() {
        statusItem.isVisible = true
        scheduleAutoHide()
    }

    private func scheduleAutoHide() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
        guard autoHideOn else { return }
        autoHideTimer = Timer.scheduledTimer(
            withTimeInterval: Self.autoHideDelay,
            repeats: false
        ) { [weak self] _ in
            self?.statusItem.isVisible = false
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        autoHideTimer?.invalidate()
        refreshState()
    }

    func menuDidClose(_ menu: NSMenu) {
        scheduleAutoHide()
    }

    @objc private func toggleEnabled() {
        interceptEnabled.toggle()
        interceptor.isEnabled = interceptEnabled
        refreshState()
    }

    @objc private func toggleAutoHide() {
        autoHideOn.toggle()
        refreshState()
        scheduleAutoHide()
    }

    @objc private func toggleLoginItem() {
        LoginItem.setEnabled(!LoginItem.isEnabled)
        refreshState()
    }

    @objc private func requestAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func openCoffeeLink() {
        if let url = URL(string: "https://buymeacoffee.com/myraas") {
            NSWorkspace.shared.open(url)
        }
    }

    private func refreshState() {
        enabledItem.state = interceptEnabled ? .on : .off
        autoHideItem.state = autoHideOn ? .on : .off
        loginItem.state = LoginItem.isEnabled ? .on : .off

        statusItem.button?.alphaValue = interceptEnabled ? 1.0 : 0.4

        let trusted = AXIsProcessTrusted()
        if trusted {
            UserDefaults.standard.set(true, forKey: Self.everTrustedKey)
            accessibilityItem.title = "Accessibility Permission Granted"
            accessibilityItem.isEnabled = false
        } else {
            accessibilityItem.title = "Grant Accessibility Permission…"
            accessibilityItem.isEnabled = true
        }
    }

    private func startPermissionPolling() {
        let timer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if AXIsProcessTrusted() {
                self.refreshState()
                self.interceptor.restart()
                self.permissionTimer?.invalidate()
                self.permissionTimer = nil
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        permissionTimer = timer
    }

    private static func runTccutilReset() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        p.arguments = ["reset", "Accessibility", LoginItem.label]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try? p.run()
        p.waitUntilExit()
    }
}
