import ArgumentParser
import CoreGraphics
import TairuCore

struct MoveCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "move",
        abstract: "Move windows to another display"
    )

    @Option(name: .long, help: "Bundle ID of the app to move")
    var app: String?

    @Option(name: .long, help: "Source display UUID (move all windows from this display)")
    var from: String?

    @Option(name: .long, help: "Target display UUID")
    var to: String

    @Flag(name: .long, help: "Show what would be moved without actually moving")
    var dryRun = false

    func validate() throws {
        if app == nil, from == nil {
            throw ValidationError("Either --app or --from must be specified")
        }
        if app != nil, from != nil {
            throw ValidationError("Cannot specify both --app and --from")
        }
    }

    func run() throws {
        let targetDisplay = try DisplayService.findDisplay(byUUID: to)

        if let appBundleId = app {
            try moveAppWindows(appBundleId: appBundleId, to: targetDisplay)
        } else if let sourceUUID = from {
            try moveAllWindows(from: sourceUUID, to: targetDisplay)
        }
    }

    private func moveAppWindows(appBundleId: String, to targetDisplay: Display) throws {
        let refs = try WindowQueryService.getAllWindowRefs()
        let appRefs = refs.filter { $0.appBundleId == appBundleId }

        if appRefs.isEmpty {
            print("No windows found for \(appBundleId)")
            return
        }

        var moved = 0
        for ref in appRefs {
            guard let currentFrame = AXService.getWindowFrame(ref.axElement) else {
                continue
            }

            let newOrigin = calculateTargetOrigin(
                windowFrame: currentFrame,
                targetDisplay: targetDisplay
            )

            if dryRun {
                let title = ref.title ?? "Untitled"
                print("[dry-run] Would move '\(title)' to \(Int(newOrigin.x)), \(Int(newOrigin.y))")
                moved += 1
            } else {
                if AXService.setWindowPosition(ref.axElement, to: newOrigin) {
                    moved += 1
                }
            }
        }

        if dryRun {
            print("[dry-run] Would move \(moved) window(s)")
        } else {
            print("Moved \(moved) window(s)")
        }
    }

    private func moveAllWindows(from sourceUUID: String, to targetDisplay: Display) throws {
        let sourceDisplay = try DisplayService.findDisplay(byUUID: sourceUUID)
        let refs = try WindowQueryService.getWindowRefs(on: sourceDisplay)

        if refs.isEmpty {
            print("No windows found on source display")
            return
        }

        var moved = 0
        for ref in refs {
            guard let currentFrame = AXService.getWindowFrame(ref.axElement) else {
                continue
            }

            let relativeX = currentFrame.origin.x - sourceDisplay.visibleFrame.origin.x
            let relativeY = currentFrame.origin.y - sourceDisplay.visibleFrame.origin.y

            let newOrigin = CGPoint(
                x: targetDisplay.visibleFrame.origin.x + relativeX,
                y: targetDisplay.visibleFrame.origin.y + relativeY
            )

            if dryRun {
                let title = ref.title ?? "Untitled"
                print("[dry-run] Would move '\(title)' to \(Int(newOrigin.x)), \(Int(newOrigin.y))")
                moved += 1
            } else {
                if AXService.setWindowPosition(ref.axElement, to: newOrigin) {
                    moved += 1
                }
            }
        }

        if dryRun {
            print("[dry-run] Would move \(moved) window(s)")
        } else {
            print("Moved \(moved) window(s)")
        }
    }

    private func calculateTargetOrigin(windowFrame _: CGRect, targetDisplay: Display) -> CGPoint {
        CGPoint(
            x: targetDisplay.visibleFrame.origin.x,
            y: targetDisplay.visibleFrame.origin.y
        )
    }
}
