import AppKit

guard SingleInstance.acquireOrPing() else { exit(0) }

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
