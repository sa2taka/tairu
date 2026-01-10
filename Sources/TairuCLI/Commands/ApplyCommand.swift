import ArgumentParser
import TairuCore

struct ApplyCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "apply",
        abstract: "Apply a saved layout"
    )

    @Option(name: .shortAndLong, help: "Display UUID (default: use saved display)")
    var display: String?

    @Option(name: .shortAndLong, help: "Name of the layout to apply")
    var name: String

    @Flag(name: .long, help: "Show what would be applied without actually applying")
    var dryRun = false

    func run() throws {
        let layout = try LayoutStore.load(name: name)
        let displayUUID = display ?? layout.targetDisplay.displayUUID
        let targetDisplay = try DisplayService.findDisplay(byUUID: displayUUID)

        let result = try LayoutEngine.apply(layout, to: targetDisplay, dryRun: dryRun)

        if dryRun {
            print("[dry-run] Would apply \(result.applied) windows")
        } else {
            print("Applied: \(result.applied)")
        }

        if result.skipped > 0 {
            print("Skipped: \(result.skipped)")
        }

        if !result.failed.isEmpty {
            print("Failed:")
            for failure in result.failed {
                print("  • \(failure.app): \(failure.reason)")
            }
        }
    }
}
