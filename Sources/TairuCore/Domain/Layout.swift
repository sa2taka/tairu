import Foundation

public struct Layout: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let targetDisplay: TargetDisplay
    public let windows: [WindowRule]

    public init(targetDisplay: TargetDisplay, windows: [WindowRule]) {
        self.schemaVersion = Self.currentSchemaVersion
        self.targetDisplay = targetDisplay
        self.windows = windows
    }
}

public struct TargetDisplay: Codable, Equatable, Sendable {
    public let displayUUID: String

    public init(displayUUID: String) {
        self.displayUUID = displayUUID
    }
}

public struct WindowRule: Codable, Equatable, Sendable {
    public let appBundleId: String
    public let titleMatch: TitleMatch?
    public let frameNorm: NormalizedFrame
    public let indexHint: Int?

    public init(
        appBundleId: String,
        titleMatch: TitleMatch?,
        frameNorm: NormalizedFrame,
        indexHint: Int?
    ) {
        self.appBundleId = appBundleId
        self.titleMatch = titleMatch
        self.frameNorm = frameNorm
        self.indexHint = indexHint
    }
}

public struct NormalizedFrame: Codable, Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let w: Double
    public let h: Double

    public init(x: Double, y: Double, w: Double, h: Double) {
        self.x = x
        self.y = y
        self.w = w
        self.h = h
    }
}
