import ArgumentParser
import Darwin
import Foundation
import TairuCore

struct AgentCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "agent",
        abstract: "Monitor display connections and auto-apply layouts"
    )

    @Flag(name: .long, help: "Install as launchd agent")
    var install = false

    @Flag(name: .long, help: "Uninstall launchd agent")
    var uninstall = false

    @Flag(name: .long, help: "Show agent status")
    var status = false

    private static let agentLabel = "com.example.tairu.agent"
    private static var plistPath: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents/\(agentLabel).plist")
    }

    func run() throws {
        if install {
            try installAgent()
            return
        }

        if uninstall {
            try uninstallAgent()
            return
        }

        if status {
            showStatus()
            return
        }

        try runForeground()
    }

    private func runForeground() throws {
        print("Starting tairu agent...")
        print("Press Ctrl+C to stop")
        print()

        let monitor = DisplayMonitor()

        monitor.onDisplayChange = { event in
            switch event {
            case let .displayAdded(display):
                handleDisplayAdded(display)
            case let .displayRemoved(uuid):
                print("Display removed: \(uuid)")
            }
        }

        try monitor.start()

        signal(SIGINT) { _ in
            print("\nStopping agent...")
            Darwin.exit(0)
        }
        signal(SIGTERM) { _ in
            print("\nStopping agent...")
            Darwin.exit(0)
        }

        RunLoop.current.run()
    }

    private func handleDisplayAdded(_ display: Display) {
        let name = display.name ?? display.uuid
        print("Display added: \(name)")

        let layoutNames = LayoutStore.list()
        var matchingLayouts: [(name: String, layout: Layout)] = []

        for layoutName in layoutNames {
            guard let layout = try? LayoutStore.load(name: layoutName) else {
                continue
            }
            if layout.targetDisplay.displayUUID == display.uuid {
                matchingLayouts.append((name: layoutName, layout: layout))
            }
        }

        if matchingLayouts.isEmpty {
            print("  No matching layouts found for this display")
            return
        }

        for (layoutName, layout) in matchingLayouts {
            print("  Applying layout: \(layoutName)")
            do {
                let result = try LayoutEngine.apply(layout, to: display)
                print("    Applied \(result.applied) windows")
            } catch {
                print("    Failed to apply: \(error.localizedDescription)")
            }
        }
    }

    private func installAgent() throws {
        guard let execPath = Bundle.main.executablePath else {
            print("Could not determine executable path")
            throw ExitCode.failure
        }

        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(Self.agentLabel)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(execPath)</string>
                <string>agent</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>StandardOutPath</key>
            <string>/tmp/tairu-agent.log</string>
            <key>StandardErrorPath</key>
            <string>/tmp/tairu-agent.log</string>
        </dict>
        </plist>
        """

        let plistURL = Self.plistPath
        let directory = plistURL.deletingLastPathComponent()

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try plist.write(to: plistURL, atomically: true, encoding: .utf8)

        print("Created plist at: \(plistURL.path)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["load", plistURL.path]
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            print("Agent installed and started")
        } else {
            print("Failed to load agent (exit code: \(process.terminationStatus))")
        }
    }

    private func uninstallAgent() throws {
        let plistURL = Self.plistPath

        if FileManager.default.fileExists(atPath: plistURL.path) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            process.arguments = ["unload", plistURL.path]
            try process.run()
            process.waitUntilExit()

            try FileManager.default.removeItem(at: plistURL)
            print("Agent uninstalled")
        } else {
            print("Agent is not installed")
        }
    }

    private func showStatus() {
        let plistURL = Self.plistPath

        if FileManager.default.fileExists(atPath: plistURL.path) {
            print("Agent plist: installed at \(plistURL.path)")

            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            process.arguments = ["list"]
            process.standardOutput = pipe

            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    if output.contains(Self.agentLabel) {
                        print("Agent status: running")
                    } else {
                        print("Agent status: not running")
                    }
                }
            } catch {
                print("Could not check agent status")
            }
        } else {
            print("Agent: not installed")
        }
    }
}
