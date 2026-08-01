import Foundation

public struct ReminderDraft: Sendable {
    public var hour: Int
    public var minute: Int
    public var text: String
    public var weekdays: Set<Int>
    public var isEnabled: Bool
    public var voice: ReminderVoice
    public var audioFilePath: String?

    public init(
        hour: Int,
        minute: Int,
        text: String,
        weekdays: Set<Int> = Set(1...7),
        isEnabled: Bool = true,
        voice: ReminderVoice = .systemSpeech,
        audioFilePath: String? = nil
    ) {
        self.hour = hour
        self.minute = minute
        self.text = text
        self.weekdays = weekdays
        self.isEnabled = isEnabled
        self.voice = voice
        self.audioFilePath = audioFilePath
    }

    public init(_ item: ReminderItem) {
        self.init(
            hour: item.hour,
            minute: item.minute,
            text: item.text,
            weekdays: item.weekdays,
            isEnabled: item.isEnabled,
            voice: item.voice,
            audioFilePath: item.audioFilePath
        )
    }

    public var validationMessage: String? {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "请输入播报内容"
        }
        if weekdays.isEmpty {
            return "请至少选择一天"
        }
        if voice == .audioFile && (audioFilePath?.isEmpty ?? true) {
            return "请选择自己的录音文件"
        }
        return nil
    }
}

public enum ReminderEditingError: LocalizedError {
    case invalid(String)
    case itemNotFound

    public var errorDescription: String? {
        switch self {
        case let .invalid(message): message
        case .itemNotFound: "找不到这条提醒"
        }
    }
}

public struct ReminderListEditor: Sendable {
    public private(set) var items: [ReminderItem]

    public init(items: [ReminderItem]) {
        self.items = items
    }

    @discardableResult
    public mutating func add(_ draft: ReminderDraft) throws -> ReminderItem {
        if let message = draft.validationMessage {
            throw ReminderEditingError.invalid(message)
        }
        let item = makeItem(id: UUID(), from: draft)
        items.append(item)
        sort()
        return item
    }

    public mutating func update(_ id: UUID, with draft: ReminderDraft) throws {
        if let message = draft.validationMessage {
            throw ReminderEditingError.invalid(message)
        }
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw ReminderEditingError.itemNotFound
        }
        items[index] = makeItem(id: id, from: draft)
        sort()
    }

    public mutating func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
    }

    private func makeItem(id: UUID, from draft: ReminderDraft) -> ReminderItem {
        ReminderItem(
            id: id,
            hour: draft.hour,
            minute: draft.minute,
            text: draft.text.trimmingCharacters(in: .whitespacesAndNewlines),
            weekdays: draft.weekdays,
            isEnabled: draft.isEnabled,
            voice: draft.voice,
            audioFilePath: draft.audioFilePath
        )
    }

    private mutating func sort() {
        items.sort { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
    }
}
