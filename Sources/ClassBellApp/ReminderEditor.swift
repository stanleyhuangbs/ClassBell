import AppKit
import ClassBellCore
import SwiftUI

struct ReminderEditor: View {
    let title: String
    let onSave: (ReminderDraft) throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var hour: Int
    @State private var minute: Int
    @State private var text: String
    @State private var weekdays: Set<Int>
    @State private var voice: ReminderVoice
    @State private var audioFilePath: String?
    @State private var errorMessage: String?

    init(
        title: String,
        item: ReminderItem? = nil,
        onSave: @escaping (ReminderDraft) throws -> Void
    ) {
        self.title = title
        self.onSave = onSave
        _hour = State(initialValue: item?.hour ?? 9)
        _minute = State(initialValue: item?.minute ?? 0)
        _text = State(initialValue: item?.text ?? "")
        _weekdays = State(initialValue: item?.weekdays ?? Set(2...6))
        _voice = State(initialValue: item?.voice ?? .systemSpeech)
        _audioFilePath = State(initialValue: item?.audioFilePath)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
            HStack {
                Picker("小时", selection: $hour) {
                    ForEach(0..<24) { Text(String(format: "%02d", $0)).tag($0) }
                }
                Picker("分钟", selection: $minute) {
                    ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                }
            }
            TextField("例如：上课了，本节课四十分钟", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
            VStack(alignment: .leading, spacing: 8) {
                Text("重复").font(.headline)
                HStack {
                    ForEach(Array(zip(1...7, ["日", "一", "二", "三", "四", "五", "六"])), id: \.0) { day, label in
                        Button(label) {
                            if weekdays.contains(day) { weekdays.remove(day) }
                            else { weekdays.insert(day) }
                        }
                        .buttonStyle(.bordered)
                        .tint(weekdays.contains(day) ? .green : .gray)
                    }
                }
            }
            Picker("人声", selection: $voice) {
                Text("系统中文语音").tag(ReminderVoice.systemSpeech)
                Text("使用自己的录音").tag(ReminderVoice.audioFile)
            }
            .pickerStyle(.segmented)
            if voice == .audioFile {
                HStack {
                    Text(audioFilePath.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "尚未选择录音")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("选择音频…") { chooseAudio() }
                }
            }
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.caption)
            }
            HStack {
                Button("取消") { dismiss() }
                Spacer()
                Button("保存") { save() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(26)
        .frame(width: 520)
    }

    private func chooseAudio() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            audioFilePath = panel.url?.path
        }
    }

    private func save() {
        let draft = ReminderDraft(
            hour: hour,
            minute: minute,
            text: text,
            weekdays: weekdays,
            voice: voice,
            audioFilePath: audioFilePath
        )
        do {
            try onSave(draft)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
