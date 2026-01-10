import CoreGraphics
import os

private let logger = Logger(subsystem: "com.example.tairu", category: "DisplayMonitor")

public final class DisplayMonitor: @unchecked Sendable {
    public enum Event {
        case displayAdded(Display)
        case displayRemoved(uuid: String)
    }

    public var onDisplayChange: ((Event) -> Void)?

    private var isRunning = false
    private var knownDisplayUUIDs: Set<String> = []

    public init() {}

    public func start() throws {
        guard !isRunning else { return }

        let displays = try DisplayService.getAllDisplays()
        knownDisplayUUIDs = Set(displays.map(\.uuid))

        let result = CGDisplayRegisterReconfigurationCallback(
            displayReconfigurationCallback,
            Unmanaged.passUnretained(self).toOpaque()
        )

        guard result == .success else {
            throw TairuError.monitorStartFailed
        }

        isRunning = true
        logger.info("DisplayMonitor started with \(self.knownDisplayUUIDs.count) displays")
    }

    public func stop() {
        guard isRunning else { return }

        CGDisplayRemoveReconfigurationCallback(
            displayReconfigurationCallback,
            Unmanaged.passUnretained(self).toOpaque()
        )

        isRunning = false
        logger.info("DisplayMonitor stopped")
    }

    fileprivate func handleReconfiguration(flags: CGDisplayChangeSummaryFlags) {
        guard flags.contains(.addFlag) || flags.contains(.removeFlag) else {
            return
        }

        guard let currentDisplays = try? DisplayService.getAllDisplays() else {
            return
        }

        let currentUUIDs = Set(currentDisplays.map(\.uuid))

        let addedUUIDs = currentUUIDs.subtracting(knownDisplayUUIDs)
        let removedUUIDs = knownDisplayUUIDs.subtracting(currentUUIDs)

        for uuid in addedUUIDs {
            if let display = currentDisplays.first(where: { $0.uuid == uuid }) {
                logger.info("Display added: \(display.name ?? uuid)")
                onDisplayChange?(.displayAdded(display))
            }
        }

        for uuid in removedUUIDs {
            logger.info("Display removed: \(uuid)")
            onDisplayChange?(.displayRemoved(uuid: uuid))
        }

        knownDisplayUUIDs = currentUUIDs
    }
}

private func displayReconfigurationCallback(
    _: CGDirectDisplayID,
    flags: CGDisplayChangeSummaryFlags,
    userInfo: UnsafeMutableRawPointer?
) {
    guard let userInfo else { return }

    let monitor = Unmanaged<DisplayMonitor>.fromOpaque(userInfo).takeUnretainedValue()
    monitor.handleReconfiguration(flags: flags)
}
