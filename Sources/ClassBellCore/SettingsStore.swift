import Foundation

public struct SettingsStore: Sendable {
    public let directory: URL

    public init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("ClassBell", isDirectory: true)
    }

    public var fileURL: URL {
        directory.appendingPathComponent("settings.json")
    }

    public func load() throws -> AppSettings {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .default
        }
        return try JSONDecoder().decode(
            AppSettings.self,
            from: Data(contentsOf: fileURL)
        )
    }

    public func save(_ settings: AppSettings) throws {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(settings).write(to: fileURL, options: .atomic)
    }
}
