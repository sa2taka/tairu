import ArgumentParser
import TairuCore

struct DeleteCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a saved layout"
    )

    @Option(name: .shortAndLong, help: "Name of the layout to delete")
    var name: String

    func run() throws {
        try LayoutStore.delete(name: name)
        print("Deleted layout '\(name)'")
    }
}
