import ApplicationServices
import CoreGraphics
import os

private let logger = Logger(subsystem: "com.example.tairu", category: "AXService")

public enum AXService {
    public static func checkAccessibility() -> Bool {
        AXIsProcessTrusted()
    }

    public static func requestAccessibility() -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    public static func getWindowPosition(_ element: AXUIElement) -> CGPoint? {
        var positionRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionRef)

        guard result == .success, let positionRef else {
            logger.debug("Failed to get window position: \(result.rawValue)")
            return nil
        }

        var point = CGPoint.zero
        // swiftlint:disable:next force_cast
        let axValue = positionRef as! AXValue
        guard AXValueGetValue(axValue, .cgPoint, &point) else {
            return nil
        }

        return point
    }

    public static func getWindowSize(_ element: AXUIElement) -> CGSize? {
        var sizeRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef)

        guard result == .success, let sizeRef else {
            logger.debug("Failed to get window size: \(result.rawValue)")
            return nil
        }

        var size = CGSize.zero
        // swiftlint:disable:next force_cast
        let axValue = sizeRef as! AXValue
        guard AXValueGetValue(axValue, .cgSize, &size) else {
            return nil
        }

        return size
    }

    public static func getWindowFrame(_ element: AXUIElement) -> CGRect? {
        guard let position = getWindowPosition(element),
              let size = getWindowSize(element)
        else {
            return nil
        }

        return CGRect(origin: position, size: size)
    }

    public static func setWindowPosition(_ element: AXUIElement, to point: CGPoint) -> Bool {
        var mutablePoint = point
        guard let value = AXValueCreate(.cgPoint, &mutablePoint) else {
            logger.error("Failed to create AXValue for position")
            return false
        }

        let result = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, value)
        if result != .success {
            logger.error("Failed to set window position: \(result.rawValue)")
            return false
        }

        return true
    }

    public static func setWindowSize(_ element: AXUIElement, to size: CGSize) -> Bool {
        var mutableSize = size
        guard let value = AXValueCreate(.cgSize, &mutableSize) else {
            logger.error("Failed to create AXValue for size")
            return false
        }

        let result = AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, value)
        if result != .success {
            logger.error("Failed to set window size: \(result.rawValue)")
            return false
        }

        return true
    }

    public static func setWindowFrame(_ element: AXUIElement, to frame: CGRect) -> Bool {
        let positionSuccess = setWindowPosition(element, to: frame.origin)
        let sizeSuccess = setWindowSize(element, to: frame.size)
        return positionSuccess && sizeSuccess
    }

    public static func getWindowTitle(_ element: AXUIElement) -> String? {
        var titleRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleRef)

        guard result == .success, let titleRef else {
            return nil
        }

        return titleRef as? String
    }

    public static func isWindowMinimized(_ element: AXUIElement) -> Bool {
        var minimizedRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXMinimizedAttribute as CFString, &minimizedRef)

        guard result == .success, let minimizedRef else {
            return false
        }

        return (minimizedRef as? Bool) ?? false
    }

    public static func getWindows(for app: AXUIElement) -> [AXUIElement] {
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success, let windowsRef else {
            return []
        }

        guard let windows = windowsRef as? [AXUIElement] else {
            return []
        }

        return windows
    }

    public static func createApplicationElement(pid: pid_t) -> AXUIElement {
        AXUIElementCreateApplication(pid)
    }
}
