import CoreGraphics

public struct Display: Sendable {
    public let uuid: String
    public let name: String?
    public let frame: CGRect
    public let visibleFrame: CGRect
    /// visibleFrame in AX coordinate system (top-left origin, Y increases downward)
    public let visibleFrameAX: CGRect

    public init(uuid: String, name: String?, frame: CGRect, visibleFrame: CGRect, visibleFrameAX: CGRect) {
        self.uuid = uuid
        self.name = name
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.visibleFrameAX = visibleFrameAX
    }
}

extension Display: Equatable {
    public static func == (lhs: Display, rhs: Display) -> Bool {
        lhs.uuid == rhs.uuid
            && lhs.name == rhs.name
            && lhs.frame.equalTo(rhs.frame)
            && lhs.visibleFrame.equalTo(rhs.visibleFrame)
            && lhs.visibleFrameAX.equalTo(rhs.visibleFrameAX)
    }
}
