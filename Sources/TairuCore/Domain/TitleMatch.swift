import Foundation

public enum TitleMatch: Codable, Equatable, Sendable {
    case exact(String)
    case regex(String)

    private enum CodingKeys: String, CodingKey {
        case exact
        case regex
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let exactValue = try container.decodeIfPresent(String.self, forKey: .exact) {
            self = .exact(exactValue)
        } else if let regexValue = try container.decodeIfPresent(String.self, forKey: .regex) {
            self = .regex(regexValue)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "TitleMatch must have either 'exact' or 'regex' key"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .exact(value):
            try container.encode(value, forKey: .exact)
        case let .regex(value):
            try container.encode(value, forKey: .regex)
        }
    }

    public func matches(_ title: String?) -> Bool {
        guard let title else { return false }

        switch self {
        case let .exact(pattern):
            return title == pattern
        case let .regex(pattern):
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                return false
            }
            let range = NSRange(title.startIndex..., in: title)
            guard let match = regex.firstMatch(in: title, range: range) else {
                return false
            }
            return match.range == range
        }
    }
}
