import Foundation
import Testing
@testable import ClassBellCore

@Suite("每日日程")
struct DailyScheduleTests {
    @Test("跳过停用提醒并找到下一条")
    func skipsDisabledReminder() throws {
        let disabled = ReminderItem(hour: 9, minute: 0, text: "停用", isEnabled: false)
        let enabled = ReminderItem(hour: 9, minute: 30, text: "启用")
        let settings = AppSettings(
            timeZoneIdentifier: "Asia/Shanghai",
            reminders: [disabled, enabled]
        )
        let now = try #require(ISO8601DateFormatter().date(from: "2026-08-03T01:10:00Z"))
        let next = try #require(DailySchedule().nextOccurrence(after: now, settings: settings))
        #expect(next.reminder.id == enabled.id)
        #expect(next.date == ISO8601DateFormatter().date(from: "2026-08-03T01:30:00Z"))
    }

    @Test("只在所选星期触发")
    func honorsWeekdays() throws {
        let mondayOnly = ReminderItem(hour: 9, minute: 0, text: "周一", weekdays: [2])
        let settings = AppSettings(
            timeZoneIdentifier: "Asia/Shanghai",
            reminders: [mondayOnly]
        )
        let mondayAfter = try #require(ISO8601DateFormatter().date(from: "2026-08-03T02:00:00Z"))
        let next = try #require(DailySchedule().nextOccurrence(after: mondayAfter, settings: settings))
        #expect(next.date == ISO8601DateFormatter().date(from: "2026-08-10T01:00:00Z"))
    }

    @Test("空时区使用系统时区且不会崩溃")
    func acceptsSystemTimeZone() {
        let settings = AppSettings(timeZoneIdentifier: nil, reminders: [
            ReminderItem(hour: 23, minute: 59, text: "晚安")
        ])
        #expect(DailySchedule().nextOccurrence(after: Date(), settings: settings) != nil)
    }
}
