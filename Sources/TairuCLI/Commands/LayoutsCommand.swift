import ArgumentParser
import TairuCore

struct LayoutsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "layouts",
        abstract: "List saved layouts"
    )

    func run() throws {
        let layouts = LayoutStore.list()

        if layouts.isEmpty {
            print("No saved layouts")
            return
        }

        for name in layouts {
            print(name)
        }
    }
}
