import AppKit
import ApplicationServices
import CoreGraphics
import os

private let logger = Logger(subsystem: "com.example.tairu", category: "WindowQueryService")

public enum WindowQueryService {
    public static func getAllWindows() throws -> [WindowSnapshot] {
        guard AXService.checkAccessibility() else {
            throw TairuError.accessibilityNotGranted
        }

        var allWindows: [WindowSnapshot] = []

        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular,
                  let bundleId = app.bundleIdentifier
            else {
                continue
            }

            let appElement = AXService.createApplicationElement(pid: app.processIdentifier)
            let windows = AXService.getWindows(for: appElement)

            for window in windows {
                let title = AXService.getWindowTitle(window)
                let isMinimized = AXService.isWindowMinimized(window)

                guard let frame = AXService.getWindowFrame(window) else {
                    continue
                }

                let snapshot = WindowSnapshot(
                    appBundleId: bundleId,
                    title: title,
                    frame: frame,
                    isMinimized: isMinimized
                )

                allWindows.append(snapshot)
            }
        }

        logger.debug("Found \(allWindows.count) windows")
        return allWindows
    }

    public static func getWindows(on display: Display) throws -> [WindowSnapshot] {
        let allWindows = try getAllWindows()
        return allWindows.filter { window in
            guard !window.isMinimized else { return false }
            // Use findDisplay to get the display with largest intersection area
            // This ensures windows are attributed to their primary display only
            return DisplayService.findDisplay(containing: window.frame)?.uuid == display.uuid
        }
    }

    public static func getAllWindowRefs() throws -> [WindowRef] {
        guard AXService.checkAccessibility() else {
            throw TairuError.accessibilityNotGranted
        }

        var allRefs: [WindowRef] = []

        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular,
                  let bundleId = app.bundleIdentifier
            else {
                continue
            }

            let appElement = AXService.createApplicationElement(pid: app.processIdentifier)
            let windows = AXService.getWindows(for: appElement)

            for window in windows {
                let title = AXService.getWindowTitle(window)
                let ref = WindowRef(
                    appBundleId: bundleId,
                    title: title,
                    axElement: window
                )
                allRefs.append(ref)
            }
        }

        return allRefs
    }

    public static func getWindowRefs(on display: Display) throws -> [WindowRef] {
        guard AXService.checkAccessibility() else {
            throw TairuError.accessibilityNotGranted
        }

        var refs: [WindowRef] = []

        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular,
                  let bundleId = app.bundleIdentifier
            else {
                continue
            }

            let appElement = AXService.createApplicationElement(pid: app.processIdentifier)
            let windows = AXService.getWindows(for: appElement)

            for window in windows {
                guard let frame = AXService.getWindowFrame(window),
                      !AXService.isWindowMinimized(window),
                      DisplayService.findDisplay(containing: frame)?.uuid == display.uuid
                else {
                    continue
                }

                let title = AXService.getWindowTitle(window)
                let ref = WindowRef(
                    appBundleId: bundleId,
                    title: title,
                    axElement: window
                )
                refs.append(ref)
            }
        }

        return refs
    }

    /// Get all window refs including windows from other Spaces
    /// Uses private API to detect windows on other Spaces
    public static func getAllWindowRefsIncludingOtherSpaces() throws -> [WindowRef] {
        guard AXService.checkAccessibility() else {
            throw TairuError.accessibilityNotGranted
        }

        // 1. Get windows from current Space using standard API
        var allRefs = try getAllWindowRefs()

        // 2. Build a set of window IDs we already have
        var existingWindowIDs = Set<CGWindowID>()
        for ref in allRefs {
            if let windowID = PrivateAPIs.getWindowID(from: ref.axElement) {
                existingWindowIDs.insert(windowID)
            }
        }

        // 3. Get all window infos from CGWindowListCopyWindowInfo (includes other Spaces)
        let allWindowInfos = PrivateAPIs.getAllWindowInfos()

        // 4. Find windows that are not in our current list
        var appWindowCache: [pid_t: [AXUIElement]] = [:]

        for info in allWindowInfos {
            // Skip windows we already have
            if existingWindowIDs.contains(info.windowID) {
                continue
            }

            // Try to find the app
            guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == info.pid }),
                  app.activationPolicy == .regular,
                  let bundleId = app.bundleIdentifier
            else {
                continue
            }

            // Get or cache the app's windows
            if appWindowCache[info.pid] == nil {
                let appElement = AXService.createApplicationElement(pid: info.pid)
                appWindowCache[info.pid] = AXService.getWindows(for: appElement)
            }

            // Try to match by window ID using private API
            if let windows = appWindowCache[info.pid] {
                for window in windows {
                    if let windowID = PrivateAPIs.getWindowID(from: window),
                       windowID == info.windowID,
                       !existingWindowIDs.contains(windowID)
                    {
                        let title = AXService.getWindowTitle(window)
                        let ref = WindowRef(
                            appBundleId: bundleId,
                            title: title,
                            axElement: window
                        )
                        allRefs.append(ref)
                        existingWindowIDs.insert(windowID)
                        logger.debug("Found window from other Space: \(bundleId) - \(title ?? "untitled")")
                    }
                }
            }
        }

        logger.debug("Found \(allRefs.count) windows (including other Spaces)")
        return allRefs
    }
}
