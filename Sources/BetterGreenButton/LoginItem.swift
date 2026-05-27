import Foundation

enum LoginItem {
    static let label = "com.bettergreenbutton.agent"

    private static var plistPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents/\(label).plist").path
    }

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistPath)
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        enabled ? enable() : disable()
    }

    private static func enable() -> Bool {
        guard let binaryPath = Bundle.main.executablePath else { return false }

        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [binaryPath],
            "RunAtLoad": true
        ]
        guard let data = try? PropertyListSerialization.data(
            fromPropertyList: plist, format: .xml, options: 0
        ) else { return false }

        let dir = (plistPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        return (try? data.write(to: URL(fileURLWithPath: plistPath))) != nil
    }

    private static func disable() -> Bool {
        try? FileManager.default.removeItem(atPath: plistPath)
        return true
    }
}
