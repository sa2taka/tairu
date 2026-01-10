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
}
