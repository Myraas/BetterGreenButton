import AppKit
import ApplicationServices

final class GreenButtonInterceptor {
    var isEnabled: Bool = true { didSet { onStateChange?() } }
    var skipGames: Bool = true { didSet { evaluateGamingMode() } }
    private(set) var isInGamingMode: Bool = false {
        didSet { if oldValue != isInGamingMode { onStateChange?() } }
    }
    var onStateChange: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let systemWideElement = AXUIElementCreateSystemWide()
    private var finderSavedFrames: [(window: AXUIElement, frame: CGRect)] = []
    private var workspaceObservers: [NSObjectProtocol] = []

    func start() {
        guard eventTap == nil else { return }

        AXUIElementSetMessagingTimeout(systemWideElement, 0.1)

        let mask = CGEventMask(1 << CGEventType.leftMouseDown.rawValue)
        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: GreenButtonInterceptor.callback,
            userInfo: userInfo
        ) else {
            NSLog("BetterGreenButton: event tap creation failed")
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.eventTap = tap
        self.runLoopSource = source

        let nc = NSWorkspace.shared.notificationCenter
        let launch = nc.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in self?.evaluateGamingMode() }
        let terminate = nc.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in self?.evaluateGamingMode() }
        workspaceObservers = [launch, terminate]
        evaluateGamingMode()
    }

    func restart() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        let nc = NSWorkspace.shared.notificationCenter
        for obs in workspaceObservers { nc.removeObserver(obs) }
        workspaceObservers = []
        start()
    }

    private func evaluateGamingMode() {
        guard skipGames else {
            isInGamingMode = false
            return
        }
        isInGamingMode = NSWorkspace.shared.runningApplications.contains(where: isGameApp)
    }

    private func isGameApp(_ app: NSRunningApplication) -> Bool {
        guard let url = app.bundleURL else { return false }
        if url.path.hasPrefix("/System/") { return false }
        guard
            let bundle = Bundle(url: url),
            let category = bundle.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String
        else { return false }
        return category == "public.app-category.games" || category.hasSuffix("-games")
    }

    private static let callback: CGEventTapCallBack = { _, type, event, refcon in
        guard let refcon else { return Unmanaged.passUnretained(event) }
        let interceptor = Unmanaged<GreenButtonInterceptor>.fromOpaque(refcon).takeUnretainedValue()
        return interceptor.handle(type: type, event: event)
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        case .leftMouseDown:
            break
        default:
            return Unmanaged.passUnretained(event)
        }

        guard isEnabled else { return Unmanaged.passUnretained(event) }
        guard !isInGamingMode else { return Unmanaged.passUnretained(event) }
        guard AXIsProcessTrusted() else { return Unmanaged.passUnretained(event) }

        let modifiers: CGEventFlags = [.maskAlternate, .maskCommand, .maskControl, .maskShift]
        if !event.flags.intersection(modifiers).isEmpty {
            return Unmanaged.passUnretained(event)
        }

        guard let ctx = clickContext(at: event.location) else {
            return Unmanaged.passUnretained(event)
        }

        if NSRunningApplication(processIdentifier: ctx.pid)?.bundleIdentifier == "com.apple.finder" {
            handleFinder(window: ctx.window)
        } else {
            synthesizeOptionClick(at: event.location)
        }
        return nil
    }

    private struct ClickContext {
        let pid: pid_t
        let window: AXUIElement
    }

    private func clickContext(at point: CGPoint) -> ClickContext? {
        var hit: AXUIElement?
        let status = AXUIElementCopyElementAtPosition(
            systemWideElement, Float(point.x), Float(point.y), &hit
        )
        guard status == .success, let element = hit else { return nil }
        guard let button = AX.findNearestButton(from: element, maxDepth: 3) else { return nil }
        let sub = AX.subrole(button)
        guard sub == "AXFullScreenButton" || sub == "AXZoomButton" else { return nil }
        guard let window = AX.findWindow(for: button) else { return nil }
        var pid: pid_t = 0
        AXUIElementGetPid(button, &pid)
        return ClickContext(pid: pid, window: window)
    }

    private func handleFinder(window: AXUIElement) {
        if let idx = finderSavedFrames.firstIndex(where: { CFEqual($0.window, window) }) {
            let saved = finderSavedFrames[idx].frame
            finderSavedFrames.remove(at: idx)
            _ = setFrame(window: window, frame: saved)
            return
        }
        if let current = AX.frame(window) {
            finderSavedFrames.append((window, current))
        }
        synthesizeFinderFill()
    }

    private func synthesizeFinderFill() {
        let source = CGEventSource(stateID: .hidSystemState)
        let fKey: CGKeyCode = 3
        if let down = CGEvent(keyboardEventSource: source, virtualKey: fKey, keyDown: true) {
            down.flags = [.maskSecondaryFn, .maskControl]
            down.post(tap: .cghidEventTap)
        }
        if let up = CGEvent(keyboardEventSource: source, virtualKey: fKey, keyDown: false) {
            up.flags = [.maskSecondaryFn, .maskControl]
            up.post(tap: .cghidEventTap)
        }
    }

    private func setFrame(window: AXUIElement, frame: CGRect) -> Bool {
        var origin = frame.origin
        var size = frame.size
        guard
            let posValue = AXValueCreate(.cgPoint, &origin),
            let sizeValue = AXValueCreate(.cgSize, &size)
        else { return false }
        let r1 = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        let r2 = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        return r1 == .success && r2 == .success
    }

    private func synthesizeOptionClick(at location: CGPoint) {
        let source = CGEventSource(stateID: .hidSystemState)
        let leftOption: CGKeyCode = 58

        CGEvent(keyboardEventSource: source, virtualKey: leftOption, keyDown: true)?
            .post(tap: .cghidEventTap)

        if let down = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseDown,
            mouseCursorPosition: location,
            mouseButton: .left
        ) {
            down.flags = .maskAlternate
            down.post(tap: .cghidEventTap)
        }

        if let up = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseUp,
            mouseCursorPosition: location,
            mouseButton: .left
        ) {
            up.flags = .maskAlternate
            up.post(tap: .cghidEventTap)
        }

        CGEvent(keyboardEventSource: source, virtualKey: leftOption, keyDown: false)?
            .post(tap: .cghidEventTap)
    }
}
