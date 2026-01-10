import ApplicationServices
import CoreGraphics
import os

private let logger = Logger(subsystem: "com.example.tairu", category: "PrivateAPIs")

// MARK: - Private API Declarations

// Private API: Get CGWindowID from AXUIElement
// WARNING: This is an undocumented API that may break in future macOS versions
@_silgen_name("_AXUIElementGetWindow")
private func _AXUIElementGetWindow(_ element: AXUIElement, _ windowID: UnsafeMutablePointer<CGWindowID>) -> AXError

public enum PrivateAPIs {
    /// Get CGWindowID from AXUIElement using private API
    /// Returns nil if the window ID cannot be retrieved
    public static func getWindowID(from element: AXUIElement) -> CGWindowID? {
        var windowID: CGWindowID = 0
        let result = _AXUIElementGetWindow(element, &windowID)

        if result == .success, windowID != 0 {
            return windowID
        }
        return nil
    }

    /// Get all window information using CGWindowListCopyWindowInfo
    /// This is a public API that returns windows from all Spaces
    public static func getAllWindowInfos() -> [WindowInfo] {
        guard let windowList = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        return windowList.compactMap { dict -> WindowInfo? in
            guard let windowID = dict[kCGWindowNumber as String] as? CGWindowID,
                  let pid = dict[kCGWindowOwnerPID as String] as? pid_t,
                  let layer = dict[kCGWindowLayer as String] as? Int,
                  layer == 0 // Normal windows only (not menu bar, dock, etc.)
            else {
                return nil
            }

            let name = dict[kCGWindowName as String] as? String
            let ownerName = dict[kCGWindowOwnerName as String] as? String
            let bounds = dict[kCGWindowBounds as String] as? [String: CGFloat]

            var frame: CGRect?
            if let bounds {
                frame = CGRect(
                    x: bounds["X"] ?? 0,
                    y: bounds["Y"] ?? 0,
                    width: bounds["Width"] ?? 0,
                    height: bounds["Height"] ?? 0
                )
            }

            return WindowInfo(
                windowID: windowID,
                pid: pid,
                name: name,
                ownerName: ownerName,
                frame: frame
            )
        }
    }
}

// MARK: - Window Info Structure

public struct WindowInfo {
    public let windowID: CGWindowID
    public let pid: pid_t
    public let name: String?
    public let ownerName: String?
    public let frame: CGRect?
}
