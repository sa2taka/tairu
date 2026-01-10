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
        let targetDisplay = try resolveDisplay(layout: layout)

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

    private func resolveDisplay(layout: Layout) throws -> Display {
        if let specifiedUUID = display {
            return try DisplayService.findDisplay(byUUID: specifiedUUID)
        }

        switch layout.targetDisplay {
        case let .uuid(uuid):
            return try DisplayService.findDisplay(byUUID: uuid)

        case let .anyOf(uuids):
            let displays = try DisplayService.getAllDisplays()
            guard let matched = displays.first(where: { uuids.contains($0.uuid) }) else {
                throw TairuError.displayNotFound(uuid: uuids.joined(separator: ", "))
            }
            return matched

        case let .criteria(criteria):
            let displays = try DisplayService.getAllDisplays()
            let mainDisplay = DisplayService.getMainDisplay()
            guard let matched = displays.first(where: { criteria.matches($0, mainDisplay: mainDisplay) }) else {
                throw TairuError.noMatchingDisplay
            }
            return matched
        }
    }
}
