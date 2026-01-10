import ApplicationServices
import CoreGraphics

public struct WindowSnapshot: Sendable {
    public let appBundleId: String
    public let title: String?
    public let frame: CGRect
    public let isMinimized: Bool

    public init(appBundleId: String, title: String?, frame: CGRect, isMinimized: Bool) {
        self.appBundleId = appBundleId
        self.title = title
        self.frame = frame
        self.isMinimized = isMinimized
    }
}

extension WindowSnapshot: Equatable {
    public static func == (lhs: WindowSnapshot, rhs: WindowSnapshot) -> Bool {
        lhs.appBundleId == rhs.appBundleId
            && lhs.title == rhs.title
            && lhs.frame.equalTo(rhs.frame)
            && lhs.isMinimized == rhs.isMinimized
    }
}

public struct WindowRef: @unchecked Sendable {
    public let appBundleId: String
    public let title: String?
    public let axElement: AXUIElement

    public init(appBundleId: String, title: String?, axElement: AXUIElement) {
        self.appBundleId = appBundleId
        self.title = title
        self.axElement = axElement
    }
}
