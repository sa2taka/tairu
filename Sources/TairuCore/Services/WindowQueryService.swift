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
            // Use frame (not visibleFrame) for intersection check
            // because window coordinates are in CG coordinate system
            !window.isMinimized && display.frame.intersects(window.frame)
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
                      display.frame.intersects(frame)
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
