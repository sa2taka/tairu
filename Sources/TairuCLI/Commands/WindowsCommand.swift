import ArgumentParser
import TairuCore

struct WindowsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "windows",
        abstract: "List all windows (debug)"
    )

    @Option(name: .long, help: "Filter by display UUID")
    var display: String?

    @Option(name: .long, help: "Filter by app bundle ID")
    var app: String?

    func run() throws {
        let refs = try WindowQueryService.getAllWindowRefs()

        var filtered = refs

        if let displayUUID = display {
            let targetDisplay = try DisplayService.findDisplay(byUUID: displayUUID)
            filtered = filtered.filter { ref in
                guard let frame = AXService.getWindowFrame(ref.axElement) else { return false }
                return DisplayService.findDisplay(containing: frame)?.uuid == targetDisplay.uuid
            }
        }

        if let appFilter = app {
            filtered = filtered.filter { $0.appBundleId.contains(appFilter) }
        }

        if filtered.isEmpty {
            print("No windows found")
            return
        }

        print("Found \(filtered.count) windows:\n")

        for ref in filtered {
            let title = ref.title ?? "(no title)"
            let frame = AXService.getWindowFrame(ref.axElement)
            let isMinimized = AXService.isWindowMinimized(ref.axElement)

            print("App: \(ref.appBundleId)")
            print("  Title: \(title)")
            if let f = frame {
                print("  Frame: x=\(Int(f.origin.x)), y=\(Int(f.origin.y)), w=\(Int(f.width)), h=\(Int(f.height))")
                if let display = DisplayService.findDisplay(containing: f) {
                    print("  Display: \(display.name ?? display.uuid)")
                }
            } else {
                print("  Frame: (unavailable)")
            }
            print("  Minimized: \(isMinimized)")
            print()
        }
    }
}
