import CoreGraphics
import Testing

@testable import TairuCore

@Suite("DisplayCriteria")
struct DisplayCriteriaTests {
    // MARK: - Position: left

    @Test("when display is left of main, position left should match")
    func positionLeftMatches() {
        // Arrange
        let main = makeDisplay(x: 0, y: 0, width: 1920, height: 1080)
        let display = makeDisplay(x: -1080, y: 0, width: 1080, height: 1920)
        let criteria = DisplayCriteria(position: .left)

        // Act
        let result = criteria.matches(display, mainDisplay: main)

        // Assert
        #expect(result == true)
    }

    @Test("when display is right of main, position left should not match")
    func positionLeftDoesNotMatchRight() {
        // Arrange
        let main = makeDisplay(x: 0, y: 0, width: 1920, height: 1080)
        let display = makeDisplay(x: 1920, y: 0, width: 1080, height: 1920)
        let criteria = DisplayCriteria(position: .left)

        // Act
        let result = criteria.matches(display, mainDisplay: main)

        // Assert
        #expect(result == false)
    }

    // MARK: - Position: right

    @Test("when display is right of main, position right should match")
    func positionRightMatches() {
        // Arrange
        let main = makeDisplay(x: 0, y: 0, width: 1920, height: 1080)
        let display = makeDisplay(x: 1920, y: 0, width: 1080, height: 1920)
        let criteria = DisplayCriteria(position: .right)

        // Act
        let result = criteria.matches(display, mainDisplay: main)

        // Assert
        #expect(result == true)
    }

    @Test("when display is left of main, position right should not match")
    func positionRightDoesNotMatchLeft() {
        // Arrange
        let main = makeDisplay(x: 0, y: 0, width: 1920, height: 1080)
        let display = makeDisplay(x: -1080, y: 0, width: 1080, height: 1920)
        let criteria = DisplayCriteria(position: .right)

        // Act
        let result = criteria.matches(display, mainDisplay: main)

        // Assert
        #expect(result == false)
    }

    // MARK: - Position: top

    @Test("when display is above main, position top should match")
    func positionTopMatches() {
        // Arrange (macOS: left-bottom origin, so top = larger Y)
        let main = makeDisplay(x: 0, y: 0, width: 1920, height: 1080)
        let display = makeDisplay(x: 0, y: 1080, width: 1920, height: 1080)
        let criteria = DisplayCriteria(position: .top)

        // Act
        let result = criteria.matches(display, mainDisplay: main)

        // Assert
        #expect(result == true)
    }

    // MARK: - Position: bottom

    @Test("when display is below main, position bottom should match")
    func positionBottomMatches() {
        // Arrange (macOS: left-bottom origin, so bottom = smaller Y)
        let main = makeDisplay(x: 0, y: 1080, width: 1920, height: 1080)
        let display = makeDisplay(x: 0, y: 0, width: 1920, height: 1080)
        let criteria = DisplayCriteria(position: .bottom)

        // Act
        let result = criteria.matches(display, mainDisplay: main)

        // Assert
        #expect(result == true)
    }

    // MARK: - AspectRatio: portrait

    @Test("when height > width, portrait should match")
    func aspectRatioPortraitMatches() {
        // Arrange
        let display = makeDisplay(x: 0, y: 0, width: 1080, height: 1920)
        let criteria = DisplayCriteria(aspectRatio: .portrait)

        // Act
        let result = criteria.matches(display, mainDisplay: nil)

        // Assert
        #expect(result == true)
    }

    @Test("when width >= height, portrait should not match")
    func aspectRatioPortraitDoesNotMatchLandscape() {
        // Arrange
        let display = makeDisplay(x: 0, y: 0, width: 1920, height: 1080)
        let criteria = DisplayCriteria(aspectRatio: .portrait)

        // Act
        let result = criteria.matches(display, mainDisplay: nil)

        // Assert
        #expect(result == false)
    }

    // MARK: - AspectRatio: landscape

    @Test("when width >= height, landscape should match")
    func aspectRatioLandscapeMatches() {
        // Arrange
        let display = makeDisplay(x: 0, y: 0, width: 1920, height: 1080)
        let criteria = DisplayCriteria(aspectRatio: .landscape)

        // Act
        let result = criteria.matches(display, mainDisplay: nil)

        // Assert
        #expect(result == true)
    }

    @Test("when width == height, landscape should match")
    func aspectRatioLandscapeMatchesSquare() {
        // Arrange
        let display = makeDisplay(x: 0, y: 0, width: 1080, height: 1080)
        let criteria = DisplayCriteria(aspectRatio: .landscape)

        // Act
        let result = criteria.matches(display, mainDisplay: nil)

        // Assert
        #expect(result == true)
    }

    // MARK: - Combined criteria

    @Test("when both position and aspectRatio match, should return true")
    func combinedCriteriaMatches() {
        // Arrange
        let main = makeDisplay(x: 0, y: 0, width: 1920, height: 1080)
        let display = makeDisplay(x: 1920, y: 0, width: 1080, height: 1920)
        let criteria = DisplayCriteria(position: .right, aspectRatio: .portrait)

        // Act
        let result = criteria.matches(display, mainDisplay: main)

        // Assert
        #expect(result == true)
    }

    @Test("when only position matches but not aspectRatio, should return false")
    func combinedCriteriaPartialMatchPosition() {
        // Arrange
        let main = makeDisplay(x: 0, y: 0, width: 1920, height: 1080)
        let display = makeDisplay(x: 1920, y: 0, width: 1920, height: 1080)
        let criteria = DisplayCriteria(position: .right, aspectRatio: .portrait)

        // Act
        let result = criteria.matches(display, mainDisplay: main)

        // Assert
        #expect(result == false)
    }

    @Test("when only aspectRatio matches but not position, should return false")
    func combinedCriteriaPartialMatchAspect() {
        // Arrange
        let main = makeDisplay(x: 0, y: 0, width: 1920, height: 1080)
        let display = makeDisplay(x: -1080, y: 0, width: 1080, height: 1920)
        let criteria = DisplayCriteria(position: .right, aspectRatio: .portrait)

        // Act
        let result = criteria.matches(display, mainDisplay: main)

        // Assert
        #expect(result == false)
    }

    // MARK: - No mainDisplay

    @Test("when position is required but mainDisplay is nil, should return false")
    func positionWithoutMainDisplayReturnsFalse() {
        // Arrange
        let display = makeDisplay(x: 1920, y: 0, width: 1080, height: 1920)
        let criteria = DisplayCriteria(position: .right)

        // Act
        let result = criteria.matches(display, mainDisplay: nil)

        // Assert
        #expect(result == false)
    }

    // MARK: - No criteria

    @Test("when no criteria specified, should match any display")
    func noCriteriaMatchesAny() {
        // Arrange
        let display = makeDisplay(x: 0, y: 0, width: 1920, height: 1080)
        let criteria = DisplayCriteria()

        // Act
        let result = criteria.matches(display, mainDisplay: nil)

        // Assert
        #expect(result == true)
    }

    // MARK: - Helpers

    private func makeDisplay(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> Display {
        let frame = CGRect(x: x, y: y, width: width, height: height)
        return Display(
            uuid: "test-uuid",
            name: "Test Display",
            frame: frame,
            visibleFrame: frame
        )
    }
}
