import Foundation
import Testing
@testable import ClassBellCore

@Suite("提醒编辑")
struct ReminderEditorTests {
    @Test("拒绝空文案")
    func rejectsBlankText() {
        let draft = ReminderDraft(hour: 8, minute: 30, text: "   ")
        #expect(draft.validationMessage == "请输入播报内容")
    }

    @Test("新增修改和删除提醒")
    func editsReminderList() throws {
        var editor = ReminderListEditor(items: [])
        let first = try editor.add(ReminderDraft(hour: 8, minute: 30, text: "开始上课"))
        #expect(editor.items.count == 1)
        try editor.update(first.id, with: ReminderDraft(hour: 9, minute: 0, text: "回来上课"))
        #expect(editor.items.first?.hour == 9)
        editor.delete(first.id)
        #expect(editor.items.isEmpty)
    }

    @Test("自选录音必须存在")
    func customAudioMustExist() {
        let reminder = ReminderItem(
            hour: 9,
            minute: 0,
            text: "开始",
            voice: .audioFile,
            audioFilePath: "/definitely/missing.m4a"
        )
        #expect(throws: ReminderContentError.self) {
            try ReminderContentResolver().content(for: reminder)
        }
    }
}
