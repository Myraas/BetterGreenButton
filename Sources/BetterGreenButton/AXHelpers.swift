import ApplicationServices

enum AX {
    static func copyAttribute(_ element: AXUIElement, _ attribute: CFString) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else { return nil }
        return value
    }

    static func string(_ element: AXUIElement, _ attribute: CFString) -> String? {
        copyAttribute(element, attribute) as? String
    }

    static func elementAttribute(_ element: AXUIElement, _ attribute: CFString) -> AXUIElement? {
        guard let raw = copyAttribute(element, attribute) else { return nil }
        let value = raw as AnyObject
        guard CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }

    static func role(_ element: AXUIElement) -> String? {
        string(element, kAXRoleAttribute as CFString)
    }

    static func subrole(_ element: AXUIElement) -> String? {
        string(element, kAXSubroleAttribute as CFString)
    }

    static func parent(_ element: AXUIElement) -> AXUIElement? {
        elementAttribute(element, kAXParentAttribute as CFString)
    }

    static func window(_ element: AXUIElement) -> AXUIElement? {
        elementAttribute(element, kAXWindowAttribute as CFString)
    }

    static func frame(_ element: AXUIElement) -> CGRect? {
        guard
            let posRaw = copyAttribute(element, kAXPositionAttribute as CFString),
            let sizeRaw = copyAttribute(element, kAXSizeAttribute as CFString),
            CFGetTypeID(posRaw) == AXValueGetTypeID(),
            CFGetTypeID(sizeRaw) == AXValueGetTypeID()
        else { return nil }
        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(posRaw as! AXValue, .cgPoint, &point) else { return nil }
        guard AXValueGetValue(sizeRaw as! AXValue, .cgSize, &size) else { return nil }
        return CGRect(origin: point, size: size)
    }

    static func findNearestButton(from element: AXUIElement, maxDepth: Int = 3) -> AXUIElement? {
        var current: AXUIElement? = element
        var depth = 0
        while let node = current, depth <= maxDepth {
            if role(node) == (kAXButtonRole as String) { return node }
            current = parent(node)
            depth += 1
        }
        return nil
    }

    static func findWindow(for element: AXUIElement) -> AXUIElement? {
        if let direct = window(element) { return direct }
        var current: AXUIElement? = parent(element)
        while let node = current {
            if role(node) == (kAXWindowRole as String) { return node }
            current = parent(node)
        }
        return nil
    }
}
