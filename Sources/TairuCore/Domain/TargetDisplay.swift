import Foundation

/// ディスプレイのマッチング条件を表す enum
public enum TargetDisplay: Codable, Equatable, Sendable {
    /// 単一の UUID による完全一致
    case uuid(String)

    /// 複数の UUID のいずれかにマッチ (OR条件)
    case anyOf([String])

    /// 位置とアスペクト比による条件マッチ
    case criteria(DisplayCriteria)

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case uuid
        case anyOf
        case criteria
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let uuid = try container.decodeIfPresent(String.self, forKey: .uuid) {
            self = .uuid(uuid)
        } else if let uuids = try container.decodeIfPresent([String].self, forKey: .anyOf) {
            self = .anyOf(uuids)
        } else if let criteria = try container.decodeIfPresent(DisplayCriteria.self, forKey: .criteria) {
            self = .criteria(criteria)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "TargetDisplay must have 'uuid', 'anyOf', or 'criteria' key"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .uuid(value):
            try container.encode(value, forKey: .uuid)
        case let .anyOf(values):
            try container.encode(values, forKey: .anyOf)
        case let .criteria(value):
            try container.encode(value, forKey: .criteria)
        }
    }

    // MARK: - Matching

    /// ディスプレイがこの条件にマッチするか判定
    /// - Parameters:
    ///   - display: 判定対象のディスプレイ
    ///   - mainDisplay: メインディスプレイ (位置判定に使用)
    public func matches(_ display: Display, mainDisplay: Display?) -> Bool {
        switch self {
        case let .uuid(targetUUID):
            display.uuid == targetUUID

        case let .anyOf(uuids):
            uuids.contains(display.uuid)

        case let .criteria(criteria):
            criteria.matches(display, mainDisplay: mainDisplay)
        }
    }
}
