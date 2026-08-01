import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var selectedDeviceUID: String?
    public var selectedDeviceName: String?
    public var volume: Double
    public var isScheduleEnabled: Bool
    public var timeZoneIdentifier: String?
    public var reminders: [ReminderItem]

    public init(
        selectedDeviceUID: String? = nil,
        selectedDeviceName: String? = nil,
        volume: Double = 0.6,
        isScheduleEnabled: Bool = false,
        timeZoneIdentifier: String? = nil,
        reminders: [ReminderItem] = ReminderItem.sample
    ) {
        self.selectedDeviceUID = selectedDeviceUID
        self.selectedDeviceName = selectedDeviceName
        self.volume = min(max(volume, 0), 1)
        self.isScheduleEnabled = isScheduleEnabled
        self.timeZoneIdentifier = timeZoneIdentifier
        self.reminders = reminders
    }

    public static let `default` = AppSettings()

    public var timeZone: TimeZone {
        timeZoneIdentifier.flatMap(TimeZone.init(identifier:)) ?? .current
    }

    public mutating func setVolume(_ newValue: Double) {
        volume = min(max(newValue, 0), 1)
    }
}
