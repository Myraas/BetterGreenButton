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
        guard (try? data.write(to: URL(fileURLWithPath: plistPath))) != nil else { return false }

        runLaunchctl(["bootstrap", "gui/\(getuid())", plistPath])
        return true
    }

    private static func disable() -> Bool {
        runLaunchctl(["bootout", "gui/\(getuid())/\(label)"])
        try? FileManager.default.removeItem(atPath: plistPath)
        return true
    }

    private static func runLaunchctl(_ args: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = args
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }
}
