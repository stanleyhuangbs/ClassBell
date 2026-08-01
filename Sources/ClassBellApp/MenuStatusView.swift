import ClassBellCore
import SwiftUI

struct MenuStatusView: View {
    @ObservedObject var controller: AppController
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Circle()
                    .fill(controller.settings.isScheduleEnabled ? Color.green : Color.gray)
                    .frame(width: 9, height: 9)
                Text(controller.settings.isScheduleEnabled ? "日程运行中" : "日程已暂停")
                    .font(.headline)
            }
            Text(controller.statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let next = controller.nextItem {
                Divider()
                Text("下一条")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(AppController.timeText(next.date, timeZone: controller.settings.timeZone))
                    .font(.title2.monospacedDigit().weight(.bold))
                Text(next.reminder.text).lineLimit(2)
            }
            Divider()
            Button(controller.settings.isScheduleEnabled ? "暂停日程" : "启动日程") {
                controller.toggleSchedule()
            }
            Button("打开设置…") {
                openWindow(id: "settings")
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            Button("退出 ClassBell") { controller.quit() }
        }
        .padding(18)
        .frame(width: 290)
    }
}
