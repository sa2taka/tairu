import ArgumentParser
import TairuCore

struct DisplaysCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "displays",
        abstract: "List available displays"
    )

    func run() throws {
        let displays = try DisplayService.getAllDisplays()

        if displays.isEmpty {
            print("No displays found")
            return
        }

        for display in displays {
            let name = display.name ?? "Unknown"
            print("\(name)")
            print("  UUID: \(display.uuid)")
            print(
                "  Frame: \(Int(display.frame.origin.x)),\(Int(display.frame.origin.y)) \(Int(display.frame.width))x\(Int(display.frame.height))"
            )
            print(
                "  Visible: \(Int(display.visibleFrame.origin.x)),\(Int(display.visibleFrame.origin.y)) \(Int(display.visibleFrame.width))x\(Int(display.visibleFrame.height))"
            )
            print()
        }
    }
}
