import Foundation
import Testing
@testable import ClassBellCore

@Suite("应用设置")
struct AppSettingsTests {
    @Test("默认音量为百分之六十")
    func defaultVolume() {
        #expect(AppSettings.default.volume == 0.6)
    }

    @Test("音量限制在有效范围")
    func clampsVolume() {
        #expect(AppSettings(volume: 1.4).volume == 1)
        #expect(AppSettings(volume: -0.2).volume == 0)
    }

    @Test("设置可以完整保存和读取")
    func roundTrip() throws {
        let reminder = ReminderItem(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            hour: 9,
            minute: 0,
            text: "上课了",
            weekdays: [2, 3, 4, 5, 6]
        )
        let settings = AppSettings(
            selectedDeviceUID: "speaker-uid",
            selectedDeviceName: "教室音箱",
            volume: 0.72,
            isScheduleEnabled: true,
            timeZoneIdentifier: "Asia/Shanghai",
            reminders: [reminder]
        )
        let data = try JSONEncoder().encode(settings)
        #expect(try JSONDecoder().decode(AppSettings.self, from: data) == settings)
    }

    @Test("设置存储使用指定目录")
    func fileStore() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = SettingsStore(directory: directory)
        let settings = AppSettings(volume: 0.45)
        try store.save(settings)
        #expect(try store.load() == settings)
        try? FileManager.default.removeItem(at: directory)
    }
}
