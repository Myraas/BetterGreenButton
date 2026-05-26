import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let interceptor = GreenButtonInterceptor()
    private var menu: StatusMenuController?
    private var showIconObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        resetOptInSettingsIfFreshInstall()
        let menu = StatusMenuController(interceptor: interceptor)
        self.menu = menu

        showIconObserver = DistributedNotificationCenter.default().addObserver(
            forName: SingleInstance.showIconNotification,
            object: nil,
            queue: .main
        ) { [weak menu] _ in
            menu?.showIcon()
        }

        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)

        interceptor.start()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        menu?.showIcon()
        interceptor.restart()
        return false
    }

    private func resetOptInSettingsIfFreshInstall() {
        guard let path = Bundle.main.executablePath,
              let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let modDate = attrs[.modificationDate] as? Date
        else { return }
        let mark = String(modDate.timeIntervalSince1970)
        let stored = UserDefaults.standard.string(forKey: "BetterGreenButton.installMark")
        guard mark != stored else { return }
        UserDefaults.standard.removeObject(forKey: "BetterGreenButton.autoHide")
        LoginItem.setEnabled(false)
        UserDefaults.standard.set(mark, forKey: "BetterGreenButton.installMark")
    }
}
