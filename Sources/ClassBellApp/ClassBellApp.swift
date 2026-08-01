import SwiftUI

@main
struct ClassBellApp: App {
    @StateObject private var controller = AppController()

    var body: some Scene {
        MenuBarExtra {
            MenuStatusView(controller: controller)
        } label: {
            Label("ClassBell", systemImage: controller.settings.isScheduleEnabled
                ? "bell.and.waves.left.and.right.fill"
                : "bell.slash.fill")
        }
        .menuBarExtraStyle(.window)

        WindowGroup("ClassBell 设置", id: "settings") {
            StatusView(controller: controller)
                .frame(minWidth: 720, minHeight: 620)
        }
        .windowResizability(.contentMinSize)
    }
}
