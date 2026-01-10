import CoreGraphics

/// ディスプレイの位置（メインディスプレイ基準）
public enum RelativePosition: String, Codable, Equatable, Sendable {
    case left
    case right
    case top
    case bottom
}

/// ディスプレイのアスペクト比
public enum AspectRatio: String, Codable, Equatable, Sendable {
    /// 縦長 (height > width)
    case portrait
    /// 横長 (width >= height)
    case landscape
}

/// ディスプレイの条件マッチング用構造体
public struct DisplayCriteria: Codable, Equatable, Sendable {
    /// メインディスプレイからの相対位置
    public let position: RelativePosition?

    /// アスペクト比
    public let aspectRatio: AspectRatio?

    public init(position: RelativePosition? = nil, aspectRatio: AspectRatio? = nil) {
        self.position = position
        self.aspectRatio = aspectRatio
    }

    /// すべての条件にマッチするか判定（AND 条件）
    public func matches(_ display: Display, mainDisplay: Display?) -> Bool {
        if let requiredPosition = position {
            guard let main = mainDisplay else {
                return false
            }
            if !matchesPosition(display, main: main, required: requiredPosition) {
                return false
            }
        }

        if let requiredAspect = aspectRatio {
            if !matchesAspectRatio(display, required: requiredAspect) {
                return false
            }
        }

        return true
    }

    private func matchesPosition(_ display: Display, main: Display, required: RelativePosition) -> Bool {
        let displayFrame = display.frame
        let mainFrame = main.frame

        switch required {
        case .left:
            return displayFrame.maxX <= mainFrame.minX
        case .right:
            return displayFrame.minX >= mainFrame.maxX
        case .top:
            // macOS 座標系は左下原点なので、上 = Y 値が大きい
            return displayFrame.minY >= mainFrame.maxY
        case .bottom:
            return displayFrame.maxY <= mainFrame.minY
        }
    }

    private func matchesAspectRatio(_ display: Display, required: AspectRatio) -> Bool {
        let frame = display.frame
        switch required {
        case .portrait:
            return frame.height > frame.width
        case .landscape:
            return frame.width >= frame.height
        }
    }
}
