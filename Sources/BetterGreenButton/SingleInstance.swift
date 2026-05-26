import Foundation
import Darwin

enum SingleInstance {
    static let showIconNotification = Notification.Name("com.bettergreenbutton.showIcon")
    static let pidPath: String = NSTemporaryDirectory() + "bettergreenbutton.pid"

    static func acquireOrPing() -> Bool {
        let fd = Darwin.open(pidPath, O_CREAT | O_EXCL | O_WRONLY, 0o644)
        if fd >= 0 {
            let pid = "\(getpid())\n"
            _ = pid.withCString { write(fd, $0, strlen($0)) }
            close(fd)
            return true
        }

        let raw = try? String(contentsOfFile: pidPath, encoding: .utf8)
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, let otherPid = pid_t(trimmed), kill(otherPid, 0) == 0 {
            DistributedNotificationCenter.default().post(name: showIconNotification, object: nil)
            return false
        }

        try? FileManager.default.removeItem(atPath: pidPath)
        return acquireOrPing()
    }
}
