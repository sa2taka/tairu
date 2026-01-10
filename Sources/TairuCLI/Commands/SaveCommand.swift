import ArgumentParser
import TairuCore

struct SaveCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "save",
        abstract: "Save current window layout"
    )

    @Option(name: .shortAndLong, help: "Display UUID to save layout for")
    var display: String

    @Option(name: .shortAndLong, help: "Name for the layout")
    var name: String

    @Flag(name: .long, help: "Overwrite if layout already exists")
    var force = false

    @Flag(name: .long, help: "Show what would be saved without actually saving")
    var dryRun = false

    func run() throws {
        let targetDisplay = try DisplayService.findDisplay(byUUID: display)
        let layout = try LayoutEngine.createLayout(for: targetDisplay)

        if dryRun {
            print("Would save layout '\(name)' with \(layout.windows.count) windows:")
            for rule in layout.windows {
                let title = rule.titleMatch.map { titleMatch -> String in
                    switch titleMatch {
                    case let .exact(text): return " (\(text))"
                    case let .regex(pattern): return " [regex: \(pattern)]"
                    }
                } ?? ""
                print("  • \(rule.appBundleId)\(title)")
            }
            return
        }

        try LayoutStore.save(layout, name: name, overwrite: force)
        print("Saved layout '\(name)' with \(layout.windows.count) windows")
    }
}
