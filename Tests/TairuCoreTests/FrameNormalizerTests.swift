import CoreGraphics
import Testing

@testable import TairuCore

@Suite("FrameNormalizer")
struct FrameNormalizerTests {
    @Test("when normalizing frame at origin, should return 0,0 position")
    func normalizeFrameAtOrigin() {
        // Arrange
        let visibleFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let windowFrame = CGRect(x: 0, y: 0, width: 960, height: 540)

        // Act
        let normalized = FrameNormalizer.normalize(windowFrame, relativeTo: visibleFrame)

        // Assert
        #expect(normalized.x == 0.0)
        #expect(normalized.y == 0.0)
        #expect(normalized.w == 0.5)
        #expect(normalized.h == 0.5)
    }

    @Test("when normalizing frame at center, should return centered position")
    func normalizeFrameAtCenter() {
        // Arrange
        let visibleFrame = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        let windowFrame = CGRect(x: 250, y: 250, width: 500, height: 500)

        // Act
        let normalized = FrameNormalizer.normalize(windowFrame, relativeTo: visibleFrame)

        // Assert
        #expect(normalized.x == 0.25)
        #expect(normalized.y == 0.25)
        #expect(normalized.w == 0.5)
        #expect(normalized.h == 0.5)
    }

    @Test("when denormalizing to same display, should restore original frame")
    func denormalizeToSameDisplay() {
        // Arrange
        let visibleFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let normalized = NormalizedFrame(x: 0.25, y: 0.25, w: 0.5, h: 0.5)

        // Act
        let restored = FrameNormalizer.denormalize(normalized, to: visibleFrame)

        // Assert
        #expect(restored.origin.x == 480)
        #expect(restored.origin.y == 270)
        #expect(restored.size.width == 960)
        #expect(restored.size.height == 540)
    }

    @Test("when denormalizing to different display size, should scale proportionally")
    func denormalizeToDifferentDisplay() {
        // Arrange
        let visibleFrame = CGRect(x: 0, y: 0, width: 2560, height: 1440)
        let normalized = NormalizedFrame(x: 0.0, y: 0.0, w: 0.5, h: 0.5)

        // Act
        let restored = FrameNormalizer.denormalize(normalized, to: visibleFrame)

        // Assert
        #expect(restored.origin.x == 0)
        #expect(restored.origin.y == 0)
        #expect(restored.size.width == 1280)
        #expect(restored.size.height == 720)
    }

    @Test("when normalizing and denormalizing, should roundtrip correctly")
    func roundtrip() {
        // Arrange
        let visibleFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let originalFrame = CGRect(x: 100, y: 200, width: 800, height: 600)

        // Act
        let normalized = FrameNormalizer.normalize(originalFrame, relativeTo: visibleFrame)
        let restored = FrameNormalizer.denormalize(normalized, to: visibleFrame)

        // Assert
        #expect(abs(restored.origin.x - originalFrame.origin.x) < 1)
        #expect(abs(restored.origin.y - originalFrame.origin.y) < 1)
        #expect(abs(restored.size.width - originalFrame.size.width) < 1)
        #expect(abs(restored.size.height - originalFrame.size.height) < 1)
    }

    @Test("when display has non-zero origin, should handle offset correctly")
    func normalizeWithDisplayOffset() {
        // Arrange
        let visibleFrame = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let windowFrame = CGRect(x: 1920, y: 0, width: 960, height: 540)

        // Act
        let normalized = FrameNormalizer.normalize(windowFrame, relativeTo: visibleFrame)

        // Assert
        #expect(normalized.x == 0.0)
        #expect(normalized.y == 0.0)
        #expect(normalized.w == 0.5)
        #expect(normalized.h == 0.5)
    }
}
