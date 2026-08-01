import Foundation

public struct ScheduledItem: Equatable, Sendable {
    public let reminder: ReminderItem
    public let date: Date

    public init(reminder: ReminderItem, date: Date) {
        self.reminder = reminder
        self.date = date
    }
}

public struct DailySchedule: Sendable {
    public init() {}

    public func nextOccurrence(
        after now: Date,
        settings: AppSettings
    ) -> ScheduledItem? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = settings.timeZone

        return settings.reminders
            .filter { $0.isEnabled && !$0.weekdays.isEmpty }
            .compactMap { reminder -> ScheduledItem? in
                var components = DateComponents()
                components.hour = reminder.hour
                components.minute = reminder.minute
                components.second = 0

                var cursor = now
                for _ in 0..<8 {
                    guard let candidate = calendar.nextDate(
                        after: cursor,
                        matching: components,
                        matchingPolicy: .nextTime,
                        repeatedTimePolicy: .first,
                        direction: .forward
                    ) else {
                        return nil
                    }
                    let weekday = calendar.component(.weekday, from: candidate)
                    if reminder.weekdays.contains(weekday) {
                        return ScheduledItem(reminder: reminder, date: candidate)
                    }
                    cursor = candidate.addingTimeInterval(1)
                }
                return nil
            }
            .min { $0.date < $1.date }
    }
}
