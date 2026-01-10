import AppKit
import ApplicationServices
import Foundation
import os

private let logger = Logger(subsystem: "com.example.tairu", category: "AppLauncher")

public enum AppLauncher {
    /// Launch an application by bundle ID
    public static func launch(bundleId: String) throws {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            throw TairuError.applicationNotFound(bundleId: bundleId)
        }

        let config = NSWorkspace.OpenConfiguration()
        let semaphore = DispatchSemaphore(value: 0)

        // Use nonisolated(unsafe) to suppress SendableClosureCaptures warning
        // This is safe because we wait for the semaphore before accessing the error
        nonisolated(unsafe) var launchError: Error?

        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { _, error in
            launchError = error
            semaphore.signal()
        }

        semaphore.wait()

        if let error = launchError {
            logger.error("Failed to launch \(bundleId): \(error.localizedDescription)")
            throw error
        }

        logger.info("Launched application: \(bundleId)")
    }

    /// Wait for a window to appear for the given bundle ID
    /// Returns the AXUIElement of the first window, or nil if timeout
    public static func waitForWindow(
        bundleId: String,
        timeout: TimeInterval = 5.0,
        pollInterval: TimeInterval = 0.3
    ) -> AXUIElement? {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            if let app = NSWorkspace.shared.runningApplications.first(
                where: { $0.bundleIdentifier == bundleId }
            ) {
                let appElement = AXService.createApplicationElement(pid: app.processIdentifier)
                let windows = AXService.getWindows(for: appElement)

                // Find the first non-minimized window with a valid frame
                for window in windows {
                    if !AXService.isWindowMinimized(window),
                       AXService.getWindowFrame(window) != nil
                    {
                        logger.info("Window appeared for \(bundleId)")
                        return window
                    }
                }
            }

            Thread.sleep(forTimeInterval: pollInterval)
        }

        logger.warning("Timeout waiting for window: \(bundleId)")
        return nil
    }
}
