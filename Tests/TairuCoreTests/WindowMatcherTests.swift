import CoreGraphics
import Testing

@testable import TairuCore

@Suite("WindowMatcher")
struct WindowMatcherTests {
    // MARK: - bundleId matching

    @Test("when bundleId matches, should return window")
    func matchByBundleId() {
        // Arrange
        let windows = [
            makeWindow(bundleId: "com.apple.Safari", title: "Google"),
            makeWindow(bundleId: "com.apple.Terminal", title: "bash"),
        ]
        let rule = makeRule(bundleId: "com.apple.Safari")

        // Act
        let matched = WindowMatcher.findMatches(for: rule, in: windows)

        // Assert
        #expect(matched.count == 1)
        #expect(matched.first?.appBundleId == "com.apple.Safari")
    }

    @Test("when bundleId does not match, should return empty")
    func noMatchByBundleId() {
        // Arrange
        let windows = [
            makeWindow(bundleId: "com.apple.Safari", title: "Google"),
        ]
        let rule = makeRule(bundleId: "com.apple.Terminal")

        // Act
        let matched = WindowMatcher.findMatches(for: rule, in: windows)

        // Assert
        #expect(matched.isEmpty)
    }

    // MARK: - titleMatch exact

    @Test("when exact title matches, should return window")
    func matchByExactTitle() {
        // Arrange
        let windows = [
            makeWindow(bundleId: "com.apple.Safari", title: "Google"),
            makeWindow(bundleId: "com.apple.Safari", title: "GitHub"),
        ]
        let rule = makeRule(bundleId: "com.apple.Safari", titleMatch: .exact("Google"))

        // Act
        let matched = WindowMatcher.findMatches(for: rule, in: windows)

        // Assert
        #expect(matched.count == 1)
        #expect(matched.first?.title == "Google")
    }

    @Test("when exact title does not match, should return empty")
    func noMatchByExactTitle() {
        // Arrange
        let windows = [
            makeWindow(bundleId: "com.apple.Safari", title: "Google Search"),
        ]
        let rule = makeRule(bundleId: "com.apple.Safari", titleMatch: .exact("Google"))

        // Act
        let matched = WindowMatcher.findMatches(for: rule, in: windows)

        // Assert
        #expect(matched.isEmpty)
    }

    // MARK: - titleMatch regex

    @Test("when regex title matches, should return window")
    func matchByRegexTitle() {
        // Arrange
        let windows = [
            makeWindow(bundleId: "com.apple.Safari", title: "Google Search"),
            makeWindow(bundleId: "com.apple.Safari", title: "GitHub"),
        ]
        let rule = makeRule(bundleId: "com.apple.Safari", titleMatch: .regex("Google.*"))

        // Act
        let matched = WindowMatcher.findMatches(for: rule, in: windows)

        // Assert
        #expect(matched.count == 1)
        #expect(matched.first?.title == "Google Search")
    }

    // MARK: - indexHint

    @Test("when indexHint is provided, should return window at that index")
    func matchByIndexHint() {
        // Arrange
        let windows = [
            makeWindow(bundleId: "com.apple.Terminal", title: "bash - 1"),
            makeWindow(bundleId: "com.apple.Terminal", title: "bash - 2"),
            makeWindow(bundleId: "com.apple.Terminal", title: "bash - 3"),
        ]
        let rule = makeRule(bundleId: "com.apple.Terminal", indexHint: 1)

        // Act
        let matched = WindowMatcher.findMatches(for: rule, in: windows)

        // Assert
        #expect(matched.count == 1)
        #expect(matched.first?.title == "bash - 2")
    }

    @Test("when indexHint is out of bounds, should return empty")
    func indexHintOutOfBounds() {
        // Arrange
        let windows = [
            makeWindow(bundleId: "com.apple.Terminal", title: "bash"),
        ]
        let rule = makeRule(bundleId: "com.apple.Terminal", indexHint: 5)

        // Act
        let matched = WindowMatcher.findMatches(for: rule, in: windows)

        // Assert
        #expect(matched.isEmpty)
    }

    // MARK: - Multiple windows

    @Test("when multiple windows match bundleId without titleMatch, should return all")
    func matchMultipleWindows() {
        // Arrange
        let windows = [
            makeWindow(bundleId: "com.apple.Terminal", title: "bash - 1"),
            makeWindow(bundleId: "com.apple.Terminal", title: "bash - 2"),
            makeWindow(bundleId: "com.apple.Safari", title: "Google"),
        ]
        let rule = makeRule(bundleId: "com.apple.Terminal")

        // Act
        let matched = WindowMatcher.findMatches(for: rule, in: windows)

        // Assert
        #expect(matched.count == 2)
    }

    // MARK: - Helpers

    private func makeWindow(bundleId: String, title: String?) -> WindowSnapshot {
        WindowSnapshot(
            appBundleId: bundleId,
            title: title,
            frame: CGRect(x: 0, y: 0, width: 800, height: 600),
            isMinimized: false
        )
    }

    private func makeRule(
        bundleId: String,
        titleMatch: TitleMatch? = nil,
        indexHint: Int? = nil
    ) -> WindowRule {
        WindowRule(
            appBundleId: bundleId,
            titleMatch: titleMatch,
            frameNorm: NormalizedFrame(x: 0, y: 0, w: 0.5, h: 0.5),
            indexHint: indexHint
        )
    }
}
