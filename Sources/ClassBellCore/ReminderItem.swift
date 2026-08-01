import Foundation

public enum ReminderVoice: String, Codable, CaseIterable, Sendable {
    case systemSpeech
    case audioFile
}

public struct ReminderItem: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var hour: Int
    public var minute: Int
    public var text: String
    public var weekdays: Set<Int>
    public var isEnabled: Bool
    public var voice: ReminderVoice
    public var audioFilePath: String?

    public init(
        id: UUID = UUID(),
        hour: Int,
        minute: Int,
        text: String,
        weekdays: Set<Int> = Set(1...7),
        isEnabled: Bool = true,
        voice: ReminderVoice = .systemSpeech,
        audioFilePath: String? = nil
    ) {
        self.id = id
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
        self.text = text
        self.weekdays = weekdays.filter { (1...7).contains($0) }
        self.isEnabled = isEnabled
        self.voice = voice
        self.audioFilePath = audioFilePath
    }

    public static let sample: [ReminderItem] = [
        .init(hour: 9, minute: 0, text: "上课时间到了，现在开始学习。", weekdays: [2, 3, 4, 5, 6]),
        .init(hour: 9, minute: 40, text: "下课了，休息十分钟。", weekdays: [2, 3, 4, 5, 6])
    ]
}
