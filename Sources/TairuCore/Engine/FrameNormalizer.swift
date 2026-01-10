import CoreGraphics

public enum FrameNormalizer {
    public static func normalize(_ frame: CGRect, relativeTo visibleFrame: CGRect) -> NormalizedFrame {
        let x = (frame.origin.x - visibleFrame.origin.x) / visibleFrame.width
        let y = (frame.origin.y - visibleFrame.origin.y) / visibleFrame.height
        let w = frame.width / visibleFrame.width
        let h = frame.height / visibleFrame.height

        return NormalizedFrame(x: x, y: y, w: w, h: h)
    }

    public static func denormalize(_ normalized: NormalizedFrame, to visibleFrame: CGRect) -> CGRect {
        let x = visibleFrame.origin.x + normalized.x * visibleFrame.width
        let y = visibleFrame.origin.y + normalized.y * visibleFrame.height
        let width = normalized.w * visibleFrame.width
        let height = normalized.h * visibleFrame.height

        return CGRect(x: x, y: y, width: width, height: height)
    }
}
