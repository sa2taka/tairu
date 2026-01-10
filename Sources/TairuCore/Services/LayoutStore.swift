import Foundation
import os

private let logger = Logger(subsystem: "com.example.tairu", category: "LayoutStore")

public enum LayoutStore {
    private static var layoutsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        // swiftlint:disable:next force_unwrapping
        return appSupport!.appendingPathComponent("tairu/layouts")
    }

    public static func save(_ layout: Layout, name: String, overwrite: Bool = false) throws {
        let directory = layoutsDirectory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let fileURL = directory.appendingPathComponent("\(name).json")

        if !overwrite, FileManager.default.fileExists(atPath: fileURL.path) {
            throw TairuError.layoutAlreadyExists(name: name)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(layout)
            try data.write(to: fileURL)
            logger.info("Saved layout '\(name)' to \(fileURL.path)")
        } catch {
            throw TairuError.fileWriteFailed(path: fileURL.path, underlying: error)
        }
    }

    public static func load(name: String) throws -> Layout {
        let fileURL = layoutsDirectory.appendingPathComponent("\(name).json")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw TairuError.layoutNotFound(name: name)
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode(Layout.self, from: data)
        } catch let error as TairuError {
            throw error
        } catch {
            throw TairuError.fileReadFailed(path: fileURL.path, underlying: error)
        }
    }

    public static func delete(name: String) throws {
        let fileURL = layoutsDirectory.appendingPathComponent("\(name).json")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw TairuError.layoutNotFound(name: name)
        }

        do {
            try FileManager.default.removeItem(at: fileURL)
            logger.info("Deleted layout '\(name)'")
        } catch {
            throw TairuError.fileWriteFailed(path: fileURL.path, underlying: error)
        }
    }

    public static func list() -> [String] {
        let directory = layoutsDirectory

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        return contents
            .filter { $0.pathExtension == "json" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }

    public static func exists(name: String) -> Bool {
        let fileURL = layoutsDirectory.appendingPathComponent("\(name).json")
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
}
