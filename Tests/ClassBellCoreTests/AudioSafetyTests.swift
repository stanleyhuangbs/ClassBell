import Testing
@testable import ClassBellCore

@Suite("音频安全")
struct AudioSafetyTests {
    @Test("按设备 UID 精确匹配")
    func exactUIDMatch() {
        let devices = [
            AudioOutputDevice(id: 1, uid: "built-in", name: "Mac 扬声器"),
            AudioOutputDevice(id: 2, uid: "bluetooth", name: "蓝牙音箱")
        ]
        #expect(AudioDeviceService.matching(uid: "bluetooth", in: devices)?.id == 2)
        #expect(AudioDeviceService.matching(uid: "missing", in: devices) == nil)
    }

    @Test("播放音量会被限制")
    func playbackVolumeClamp() {
        #expect(DeviceAudioPlayer.clampedVolume(-1) == 0)
        #expect(DeviceAudioPlayer.clampedVolume(0.6) == 0.6)
        #expect(DeviceAudioPlayer.clampedVolume(3) == 1)
    }
}
