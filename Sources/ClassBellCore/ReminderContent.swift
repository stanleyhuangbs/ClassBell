import Foundation

public enum ReminderContent: Equatable, Sendable {
    case speech(String)
    case audioFile(URL)
}

public enum ReminderContentError: LocalizedError {
    case emptyText
    case audioFileMissing

    public var errorDescription: String? {
        switch self {
        case .emptyText: "播报内容不能为空"
        case .audioFileMissing: "找不到自选录音，请重新选择"
        }
    }
}

public struct ReminderContentResolver: Sendable {
    public init() {}

    public func content(for reminder: ReminderItem) throws -> ReminderContent {
        switch reminder.voice {
        case .systemSpeech:
            let text = reminder.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { throw ReminderContentError.emptyText }
            return .speech(text)
        case .audioFile:
            guard let path = reminder.audioFilePath,
                  FileManager.default.fileExists(atPath: path) else {
                throw ReminderContentError.audioFileMissing
            }
            return .audioFile(URL(fileURLWithPath: path))
        }
    }
}
