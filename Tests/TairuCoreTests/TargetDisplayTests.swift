import CoreGraphics
import Foundation
import Testing

@testable import TairuCore

@Suite("TargetDisplay")
struct TargetDisplayTests {
    // MARK: - uuid matching

    @Test("when uuid matches, should return true")
    func uuidMatches() {
        // Arrange
        let targetDisplay = TargetDisplay.uuid("ABC-123")
        let display = makeDisplay(uuid: "ABC-123")

        // Act
        let result = targetDisplay.matches(display, mainDisplay: nil)

        // Assert
        #expect(result == true)
    }

    @Test("when uuid does not match, should return false")
    func uuidDoesNotMatch() {
        // Arrange
        let targetDisplay = TargetDisplay.uuid("ABC-123")
        let display = makeDisplay(uuid: "DEF-456")

        // Act
        let result = targetDisplay.matches(display, mainDisplay: nil)

        // Assert
        #expect(result == false)
    }

    // MARK: - anyOf matching

    @Test("when one of anyOf uuids matches, should return true")
    func anyOfMatchesFirst() {
        // Arrange
        let targetDisplay = TargetDisplay.anyOf(["ABC-123", "DEF-456", "GHI-789"])
        let display = makeDisplay(uuid: "DEF-456")

        // Act
        let result = targetDisplay.matches(display, mainDisplay: nil)

        // Assert
        #expect(result == true)
    }

    @Test("when no anyOf uuid matches, should return false")
    func anyOfDoesNotMatch() {
        // Arrange
        let targetDisplay = TargetDisplay.anyOf(["ABC-123", "DEF-456"])
        let display = makeDisplay(uuid: "XYZ-999")

        // Act
        let result = targetDisplay.matches(display, mainDisplay: nil)

        // Assert
        #expect(result == false)
    }

    @Test("when anyOf is empty, should return false")
    func anyOfEmptyReturnsFalse() {
        // Arrange
        let targetDisplay = TargetDisplay.anyOf([])
        let display = makeDisplay(uuid: "ABC-123")

        // Act
        let result = targetDisplay.matches(display, mainDisplay: nil)

        // Assert
        #expect(result == false)
    }

    // MARK: - criteria matching

    @Test("when criteria matches, should return true")
    func criteriaMatches() {
        // Arrange
        let criteria = DisplayCriteria(position: .right, aspectRatio: .portrait)
        let targetDisplay = TargetDisplay.criteria(criteria)
        let main = makeDisplay(uuid: "main", x: 0, y: 0, width: 1920, height: 1080)
        let display = makeDisplay(uuid: "secondary", x: 1920, y: 0, width: 1080, height: 1920)

        // Act
        let result = targetDisplay.matches(display, mainDisplay: main)

        // Assert
        #expect(result == true)
    }

    @Test("when criteria does not match, should return false")
    func criteriaDoesNotMatch() {
        // Arrange
        let criteria = DisplayCriteria(position: .right, aspectRatio: .portrait)
        let targetDisplay = TargetDisplay.criteria(criteria)
        let main = makeDisplay(uuid: "main", x: 0, y: 0, width: 1920, height: 1080)
        let display = makeDisplay(uuid: "secondary", x: -1080, y: 0, width: 1080, height: 1920)

        // Act
        let result = targetDisplay.matches(display, mainDisplay: main)

        // Assert
        #expect(result == false)
    }

    // MARK: - JSON Decoding

    @Test("decode uuid variant from JSON")
    func decodeUUID() throws {
        // Arrange
        let json = """
        { "uuid": "ABC-123" }
        """
        let data = Data(json.utf8)

        // Act
        let decoded = try JSONDecoder().decode(TargetDisplay.self, from: data)

        // Assert
        #expect(decoded == .uuid("ABC-123"))
    }

    @Test("decode anyOf variant from JSON")
    func decodeAnyOf() throws {
        // Arrange
        let json = """
        { "anyOf": ["ABC-123", "DEF-456"] }
        """
        let data = Data(json.utf8)

        // Act
        let decoded = try JSONDecoder().decode(TargetDisplay.self, from: data)

        // Assert
        #expect(decoded == .anyOf(["ABC-123", "DEF-456"]))
    }

    @Test("decode criteria variant from JSON")
    func decodeCriteria() throws {
        // Arrange
        let json = """
        { "criteria": { "position": "right", "aspectRatio": "portrait" } }
        """
        let data = Data(json.utf8)

        // Act
        let decoded = try JSONDecoder().decode(TargetDisplay.self, from: data)

        // Assert
        let expected = TargetDisplay.criteria(DisplayCriteria(position: .right, aspectRatio: .portrait))
        #expect(decoded == expected)
    }

    @Test("decode should fail with invalid JSON")
    func decodeInvalidJSON() {
        // Arrange
        let json = """
        { "invalid": "value" }
        """
        let data = Data(json.utf8)

        // Act & Assert
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(TargetDisplay.self, from: data)
        }
    }

    // MARK: - JSON Encoding

    @Test("encode uuid variant to JSON")
    func encodeUUID() throws {
        // Arrange
        let targetDisplay = TargetDisplay.uuid("ABC-123")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        // Act
        let data = try encoder.encode(targetDisplay)
        let json = String(data: data, encoding: .utf8)

        // Assert
        #expect(json == "{\"uuid\":\"ABC-123\"}")
    }

    @Test("encode anyOf variant to JSON")
    func encodeAnyOf() throws {
        // Arrange
        let targetDisplay = TargetDisplay.anyOf(["ABC-123", "DEF-456"])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        // Act
        let data = try encoder.encode(targetDisplay)
        let json = String(data: data, encoding: .utf8)

        // Assert
        #expect(json == "{\"anyOf\":[\"ABC-123\",\"DEF-456\"]}")
    }

    @Test("encode criteria variant to JSON")
    func encodeCriteria() throws {
        // Arrange
        let criteria = DisplayCriteria(position: .right, aspectRatio: .portrait)
        let targetDisplay = TargetDisplay.criteria(criteria)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        // Act
        let data = try encoder.encode(targetDisplay)
        let json = String(data: data, encoding: .utf8)

        // Assert
        #expect(json == "{\"criteria\":{\"aspectRatio\":\"portrait\",\"position\":\"right\"}}")
    }

    // MARK: - Helpers

    private func makeDisplay(
        uuid: String,
        x: CGFloat = 0,
        y: CGFloat = 0,
        width: CGFloat = 1920,
        height: CGFloat = 1080
    ) -> Display {
        let frame = CGRect(x: x, y: y, width: width, height: height)
        return Display(
            uuid: uuid,
            name: "Test Display",
            frame: frame,
            visibleFrame: frame
        )
    }
}
