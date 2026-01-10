import ArgumentParser
import TairuCore

struct DoctorCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "doctor",
        abstract: "Check system configuration and permissions"
    )

    func run() throws {
        print("Tairu Doctor")
        print("============")
        print()

        // Check accessibility
        let hasAccessibility = AXService.checkAccessibility()
        if hasAccessibility {
            print("✓ Accessibility permission granted")
        } else {
            print("✗ Accessibility permission NOT granted")
            print("  → Enable in System Settings > Privacy & Security > Accessibility")
        }
        print()

        // Check displays
        print("Displays:")
        do {
            let displays = try DisplayService.getAllDisplays()
            for display in displays {
                let name = display.name ?? "Unknown"
                print("  • \(name)")
                print("    UUID: \(display.uuid)")
                print("    Frame: \(Int(display.frame.width))x\(Int(display.frame.height))")
                print(
                    "    Visible: \(Int(display.visibleFrame.width))x\(Int(display.visibleFrame.height))"
                )
            }
        } catch {
            print("  ✗ Failed to get displays: \(error.localizedDescription)")
        }
        print()

        // Check windows
        if hasAccessibility {
            print("Windows:")
            do {
                let windows = try WindowQueryService.getAllWindows()
                print("  Found \(windows.count) windows")
            } catch {
                print("  ✗ Failed to get windows: \(error.localizedDescription)")
            }
        } else {
            print("Windows:")
            print("  ✗ Cannot check windows without accessibility permission")
        }
        print()

        // Check layouts
        print("Saved Layouts:")
        let layouts = LayoutStore.list()
        if layouts.isEmpty {
            print("  No saved layouts")
        } else {
            for layout in layouts {
                print("  • \(layout)")
            }
        }
    }
}
