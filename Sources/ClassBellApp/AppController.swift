import AppKit
import ClassBellCore
import ServiceManagement
import SwiftUI

@MainActor
final class AppController: ObservableObject {
    @Published var settings: AppSettings
    @Published var devices: [AudioOutputDevice] = []
    @Published var statusText = "日程已暂停"
    @Published var nextItem: ScheduledItem?
    @Published var isBusy = false
    @Published var launchAtLogin = false

    private let store = SettingsStore()
    private let schedule = DailySchedule()
    private let reminderPlayer = ReminderPlayer()
    private let deviceService = AudioDeviceService()
    private let keepAlive = AudioDeviceKeepAlive()
    private var scheduleTask: Task<Void, Never>?

    init() {
        settings = (try? store.load()) ?? .default
        launchAtLogin = SMAppService.mainApp.status == .enabled
        refreshDevices()
        if settings.isScheduleEnabled { startSchedule() }
    }

    deinit {
        scheduleTask?.cancel()
    }

    func refreshDevices() {
        do {
            devices = try deviceService.outputDevices()
            if let uid = settings.selectedDeviceUID,
               !devices.contains(where: { $0.uid == uid }) {
                statusText = "所选音箱未连接；提醒不会改用 Mac 扬声器"
            }
        } catch {
            statusText = error.localizedDescription
        }
    }

    func selectDevice(uid: String?) {
        settings.selectedDeviceUID = uid
        settings.selectedDeviceName = devices.first(where: { $0.uid == uid })?.name
        persist()
        restartIfNeeded()
    }

    func setVolume(_ value: Double) {
        settings.setVolume(value)
        persist()
    }

    func toggleSchedule() {
        settings.isScheduleEnabled.toggle()
        persist()
        settings.isScheduleEnabled ? startSchedule() : pauseSchedule()
    }

    func startSchedule() {
        guard settings.selectedDeviceUID != nil else {
            settings.isScheduleEnabled = false
            persist()
            statusText = "请先选择蓝牙音箱"
            return
        }
        settings.isScheduleEnabled = true
        persist()
        scheduleTask?.cancel()
        scheduleTask = Task { [weak self] in
            await self?.runSchedule()
        }
    }

    func pauseSchedule() {
        settings.isScheduleEnabled = false
        persist()
        scheduleTask?.cancel()
        scheduleTask = nil
        nextItem = nil
        statusText = "日程已暂停"
        Task { await keepAlive.stop() }
    }

    func preview(_ reminder: ReminderItem) {
        isBusy = true
        statusText = "正在试听…"
        Task {
            defer { isBusy = false }
            do {
                try await reminderPlayer.play(reminder, settings: settings)
                statusText = "试听完成，系统默认输出未改变"
            } catch {
                statusText = error.localizedDescription
            }
        }
    }

    func add(_ draft: ReminderDraft) throws {
        var editor = ReminderListEditor(items: settings.reminders)
        try editor.add(draft)
        settings.reminders = editor.items
        persist()
        restartIfNeeded()
    }

    func update(id: UUID, draft: ReminderDraft) throws {
        var editor = ReminderListEditor(items: settings.reminders)
        try editor.update(id, with: draft)
        settings.reminders = editor.items
        persist()
        restartIfNeeded()
    }

    func delete(id: UUID) {
        var editor = ReminderListEditor(items: settings.reminders)
        editor.delete(id)
        settings.reminders = editor.items
        persist()
        restartIfNeeded()
    }

    func setReminderEnabled(id: UUID, enabled: Bool) {
        guard let index = settings.reminders.firstIndex(where: { $0.id == id }) else { return }
        settings.reminders[index].isEnabled = enabled
        persist()
        restartIfNeeded()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = enabled
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            statusText = "开机启动设置失败：\(error.localizedDescription)"
        }
    }

    func quit() {
        pauseSchedule()
        NSApplication.shared.terminate(nil)
    }

    private func runSchedule() async {
        while !Task.isCancelled && settings.isScheduleEnabled {
            refreshDevices()
            guard let uid = settings.selectedDeviceUID else { return }
            if let device = try? deviceService.targetDevice(uid: uid) {
                do { try await keepAlive.start(through: device) }
                catch { statusText = "音箱保活未启动：\(error.localizedDescription)" }
            } else {
                await keepAlive.stop()
            }

            guard let upcoming = schedule.nextOccurrence(after: Date(), settings: settings) else {
                nextItem = nil
                statusText = "没有启用的提醒"
                try? await Task.sleep(for: .seconds(30))
                continue
            }
            nextItem = upcoming
            statusText = "运行中 · 下一条 \(Self.timeText(upcoming.date, timeZone: settings.timeZone))"
            let delay = upcoming.date.timeIntervalSinceNow
            if delay > 0 {
                do { try await Task.sleep(for: .seconds(delay)) }
                catch { return }
            }
            guard !Task.isCancelled else { return }
            do {
                try await reminderPlayer.play(upcoming.reminder, settings: settings)
                statusText = "已播放：\(upcoming.reminder.text)"
            } catch {
                statusText = error.localizedDescription
            }
            try? await Task.sleep(for: .seconds(1))
        }
    }

    private func persist() {
        do { try store.save(settings) }
        catch { statusText = "保存失败：\(error.localizedDescription)" }
    }

    private func restartIfNeeded() {
        if settings.isScheduleEnabled { startSchedule() }
    }

    static func timeText(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = timeZone
        formatter.dateFormat = "E HH:mm"
        return formatter.string(from: date)
    }
}
