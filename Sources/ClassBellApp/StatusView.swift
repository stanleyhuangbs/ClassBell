import ClassBellCore
import SwiftUI

struct StatusView: View {
    @ObservedObject var controller: AppController
    @State private var editingItem: ReminderItem?
    @State private var showingNewReminder = false

    private let paper = Color(red: 0.965, green: 0.946, blue: 0.895)
    private let forest = Color(red: 0.075, green: 0.27, blue: 0.20)
    private let orange = Color(red: 0.92, green: 0.39, blue: 0.16)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                statusCard
                deviceCard
                scheduleCard
            }
            .padding(28)
        }
        .background(paper.ignoresSafeArea())
        .tint(forest)
        .sheet(isPresented: $showingNewReminder) {
            ReminderEditor(title: "添加提醒") { draft in
                try controller.add(draft)
            }
        }
        .sheet(item: $editingItem) { item in
            ReminderEditor(title: "编辑提醒", item: item) { draft in
                try controller.update(id: item.id, draft: draft)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CLASSBELL / 课铃")
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(orange)
                    .tracking(1.8)
                Text("让提醒去该去的音箱")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(forest)
            }
            Spacer()
            Toggle("日程", isOn: Binding(
                get: { controller.settings.isScheduleEnabled },
                set: { _ in controller.toggleSchedule() }
            ))
            .toggleStyle(.switch)
        }
    }

    private var statusCard: some View {
        card {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(controller.settings.isScheduleEnabled ? orange : .gray.opacity(0.35))
                    Image(systemName: controller.settings.isScheduleEnabled ? "waveform" : "pause.fill")
                        .foregroundStyle(.white)
                }
                .frame(width: 46, height: 46)
                VStack(alignment: .leading, spacing: 4) {
                    Text(controller.settings.isScheduleEnabled ? "正在守候下一次提醒" : "日程当前暂停")
                        .font(.headline)
                    Text(controller.statusText)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("登录时启动", isOn: Binding(
                    get: { controller.launchAtLogin },
                    set: { controller.setLaunchAtLogin($0) }
                ))
                .toggleStyle(.switch)
            }
        }
    }

    private var deviceCard: some View {
        card(title: "01  播放设备") {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Picker("指定音箱", selection: Binding(
                        get: { controller.settings.selectedDeviceUID },
                        set: { controller.selectDevice(uid: $0) }
                    )) {
                        Text("请选择已连接的音箱").tag(String?.none)
                        ForEach(controller.devices) { device in
                            Text(device.name).tag(Optional(device.uid))
                        }
                    }
                    Button("刷新") { controller.refreshDevices() }
                }
                HStack {
                    Text("提醒音量")
                    Slider(value: Binding(
                        get: { controller.settings.volume },
                        set: { controller.setVolume($0) }
                    ), in: 0...1, step: 0.05)
                    Text("\(Int(controller.settings.volume * 100))%")
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                        .frame(width: 48, alignment: .trailing)
                }
                Label("只改变这次提醒的音箱音量；播放结束后恢复。其他声音仍走 Mac 默认输出。", systemImage: "checkmark.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var scheduleCard: some View {
        card(title: "02  日程") {
            VStack(spacing: 0) {
                ForEach(controller.settings.reminders) { item in
                    HStack(spacing: 14) {
                        Text(String(format: "%02d:%02d", item.hour, item.minute))
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundStyle(forest)
                            .frame(width: 68, alignment: .leading)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.text).lineLimit(1)
                            Text(weekdayText(item.weekdays))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { controller.preview(item) } label: {
                            Image(systemName: "play.fill")
                        }
                        .buttonStyle(.borderless)
                        .disabled(controller.isBusy)
                        Button { editingItem = item } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.borderless)
                        Toggle("启用", isOn: Binding(
                            get: { item.isEnabled },
                            set: { controller.setReminderEnabled(id: item.id, enabled: $0) }
                        ))
                        .labelsHidden()
                    }
                    .padding(.vertical, 12)
                    if item.id != controller.settings.reminders.last?.id { Divider() }
                }
                Button {
                    showingNewReminder = true
                } label: {
                    Label("添加一条提醒", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 18)
            }
        }
    }

    private func card<Content: View>(
        title: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                Text(title)
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(forest)
            }
            content()
        }
        .padding(20)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(forest.opacity(0.13)))
        .shadow(color: forest.opacity(0.08), radius: 16, y: 8)
    }

    private func weekdayText(_ days: Set<Int>) -> String {
        if days == Set(1...7) { return "每天" }
        let labels = [1: "日", 2: "一", 3: "二", 4: "三", 5: "四", 6: "五", 7: "六"]
        return days.sorted().compactMap { labels[$0] }.map { "周\($0)" }.joined(separator: " · ")
    }
}
