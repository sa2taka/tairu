import Foundation

public enum TairuError: Error, LocalizedError {
    case accessibilityNotGranted
    case displayNotFound(uuid: String)
    case noDisplaysAvailable
    case layoutNotFound(name: String)
    case layoutAlreadyExists(name: String)
    case invalidLayoutFormat(detail: String)
    case windowOperationFailed(app: String, reason: String)
    case fileWriteFailed(path: String, underlying: Error)
    case fileReadFailed(path: String, underlying: Error)
    case monitorStartFailed
    case applicationNotFound(bundleId: String)
    case windowAppearanceTimeout(bundleId: String)

    public var errorDescription: String? {
        switch self {
        case .accessibilityNotGranted:
            "Accessibility permission not granted. Enable in System Settings > Privacy & Security > Accessibility."
        case let .displayNotFound(uuid):
            "Display not found: \(uuid)"
        case .noDisplaysAvailable:
            "No displays available"
        case let .layoutNotFound(name):
            "Layout not found: \(name)"
        case let .layoutAlreadyExists(name):
            "Layout already exists: \(name)"
        case let .invalidLayoutFormat(detail):
            "Invalid layout format: \(detail)"
        case let .windowOperationFailed(app, reason):
            "Failed to move window for \(app): \(reason)"
        case let .fileWriteFailed(path, underlying):
            "Failed to write file \(path): \(underlying.localizedDescription)"
        case let .fileReadFailed(path, underlying):
            "Failed to read file \(path): \(underlying.localizedDescription)"
        case .monitorStartFailed:
            "Failed to start display monitor"
        case let .applicationNotFound(bundleId):
            "Application not found: \(bundleId)"
        case let .windowAppearanceTimeout(bundleId):
            "Timeout waiting for window to appear: \(bundleId)"
        }
    }
}
