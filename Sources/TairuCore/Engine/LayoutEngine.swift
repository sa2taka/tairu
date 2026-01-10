import ApplicationServices
import CoreGraphics
import os

private let logger = Logger(subsystem: "com.example.tairu", category: "LayoutEngine")

public struct ApplyResult: Sendable {
    public let applied: Int
    public let skipped: Int
    public let failed: [(app: String, reason: String)]

    public init(applied: Int, skipped: Int, failed: [(app: String, reason: String)]) {
        self.applied = applied
        self.skipped = skipped
        self.failed = failed
    }
}

public enum LayoutEngine {
    public static func createLayout(for display: Display) throws -> Layout {
        let windows = try WindowQueryService.getWindows(on: display)

        var windowRules: [WindowRule] = []
        var indexTracker: [String: Int] = [:]

        for window in windows {
            let index = indexTracker[window.appBundleId, default: 0]
            indexTracker[window.appBundleId] = index + 1

            let normalizedFrame = FrameNormalizer.normalize(window.frame, relativeTo: display.visibleFrame)

            let rule = WindowRule(
                appBundleId: window.appBundleId,
                titleMatch: window.title.map { TitleMatch.exact($0) },
                frameNorm: normalizedFrame,
                indexHint: index
            )

            windowRules.append(rule)
        }

        logger.info("Created layout with \(windowRules.count) window rules")

        return Layout(
            targetDisplay: TargetDisplay(displayUUID: display.uuid),
            windows: windowRules
        )
    }

    public static func apply(_ layout: Layout, to display: Display, dryRun: Bool = false) throws -> ApplyResult {
        // Get windows from ALL displays including other Spaces (uses private API)
        let windowRefs = try WindowQueryService.getAllWindowRefsIncludingOtherSpaces()

        let snapshots = windowRefs.compactMap { ref -> WindowSnapshot? in
            guard let frame = AXService.getWindowFrame(ref.axElement) else { return nil }
            return WindowSnapshot(
                appBundleId: ref.appBundleId,
                title: ref.title,
                frame: frame,
                isMinimized: AXService.isWindowMinimized(ref.axElement)
            )
        }

        var applied = 0
        var skipped = 0
        var failed: [(app: String, reason: String)] = []

        for rule in layout.windows {
            let matches = WindowMatcher.findMatches(for: rule, in: snapshots)
            let targetFrame = FrameNormalizer.denormalize(rule.frameNorm, to: display.visibleFrame)

            if matches.isEmpty {
                // No existing window found - try to launch the application
                logger.debug("No match for rule: \(rule.appBundleId), attempting to launch")

                if dryRun {
                    logger.info("[dry-run] Would launch \(rule.appBundleId)")
                    applied += 1
                    continue
                }

                do {
                    try AppLauncher.launch(bundleId: rule.appBundleId)

                    if let window = AppLauncher.waitForWindow(bundleId: rule.appBundleId) {
                        let success = AXService.setWindowFrame(window, to: targetFrame)
                        if success {
                            logger.info("Launched and positioned \(rule.appBundleId)")
                            applied += 1
                        } else {
                            failed.append((app: rule.appBundleId, reason: "Failed to set window frame after launch"))
                        }
                    } else {
                        failed.append((app: rule.appBundleId, reason: "Timeout waiting for window"))
                    }
                } catch {
                    failed.append((app: rule.appBundleId, reason: error.localizedDescription))
                }
                continue
            }

            let matchedSnapshot = matches[0]

            guard let ref = windowRefs.first(where: {
                $0.appBundleId == matchedSnapshot.appBundleId && $0.title == matchedSnapshot.title
            }) else {
                skipped += 1
                continue
            }

            if dryRun {
                logger
                    .info(
                        "[dry-run] Would move \(rule.appBundleId) to (\(targetFrame.origin.x), \(targetFrame.origin.y), \(targetFrame.width), \(targetFrame.height))"
                    )
                applied += 1
                continue
            }

            let success = AXService.setWindowFrame(ref.axElement, to: targetFrame)
            if success {
                logger.debug("Applied frame to \(rule.appBundleId)")
                applied += 1
            } else {
                let reason = "Failed to set window frame"
                logger.warning("Failed to apply frame to \(rule.appBundleId)")
                failed.append((app: rule.appBundleId, reason: reason))
            }
        }

        logger.info("Apply result: \(applied) applied, \(skipped) skipped, \(failed.count) failed")

        return ApplyResult(applied: applied, skipped: skipped, failed: failed)
    }
}
