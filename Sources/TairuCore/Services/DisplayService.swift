import AppKit
import CoreGraphics
import os

private let logger = Logger(subsystem: "com.example.tairu", category: "DisplayService")

public enum DisplayService {
    public static func getAllDisplays() throws -> [Display] {
        var displayCount: UInt32 = 0
        var result = CGGetActiveDisplayList(0, nil, &displayCount)

        guard result == .success, displayCount > 0 else {
            logger.error("Failed to get display count")
            throw TairuError.noDisplaysAvailable
        }

        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        result = CGGetActiveDisplayList(displayCount, &displayIDs, &displayCount)

        guard result == .success else {
            logger.error("Failed to get display list")
            throw TairuError.noDisplaysAvailable
        }

        return displayIDs.compactMap { makeDisplay(from: $0) }
    }

    public static func findDisplay(byUUID uuid: String) throws -> Display {
        let displays = try getAllDisplays()
        guard let display = displays.first(where: { $0.uuid == uuid }) else {
            throw TairuError.displayNotFound(uuid: uuid)
        }
        return display
    }

    public static func getMainDisplay() -> Display? {
        let mainDisplayID = CGMainDisplayID()
        return makeDisplay(from: mainDisplayID)
    }

    public static func findDisplay(containing frame: CGRect) -> Display? {
        guard let displays = try? getAllDisplays() else { return nil }

        var bestMatch: Display?
        var maxArea: CGFloat = 0

        for display in displays {
            let intersection = frame.intersection(display.frame)
            if !intersection.isNull {
                let area = intersection.width * intersection.height
                if area > maxArea {
                    maxArea = area
                    bestMatch = display
                }
            }
        }

        return bestMatch
    }

    private static func makeDisplay(from displayID: CGDirectDisplayID) -> Display? {
        let bounds = CGDisplayBounds(displayID)
        let screen = NSScreen.screens.first { screen in
            guard let screenNumber = screen
                .deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            else {
                return false
            }
            return screenNumber == displayID
        }

        let uuid: String? = CGDisplayCreateUUIDFromDisplayID(displayID)
            .flatMap { CFUUIDCreateString(nil, $0.takeRetainedValue()) as String? }

        guard let uuid else {
            logger.warning("Could not get UUID for display \(displayID)")
            return nil
        }

        let visibleFrame = screen?.visibleFrame ?? bounds

        return Display(
            uuid: uuid,
            name: screen?.localizedName,
            frame: bounds,
            visibleFrame: visibleFrame
        )
    }
}
