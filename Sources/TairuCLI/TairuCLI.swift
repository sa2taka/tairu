import ArgumentParser

@main
struct TairuCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tairu",
        abstract: "A window layout manager for macOS",
        version: "0.1.0",
        subcommands: [
            DoctorCommand.self,
            DisplaysCommand.self,
            LayoutsCommand.self,
            SaveCommand.self,
            ApplyCommand.self,
            DeleteCommand.self,
            AgentCommand.self,
            WindowsCommand.self,
        ]
    )
}
