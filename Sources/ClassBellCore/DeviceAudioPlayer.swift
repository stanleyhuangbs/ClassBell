import AudioToolbox
import AVFoundation
import Foundation

public enum DeviceAudioPlayerError: LocalizedError {
    case audioUnitUnavailable
    case bindDeviceFailed(OSStatus)
    case defaultDeviceChanged
    case playbackFailed(String)

    public var errorDescription: String? {
        switch self {
        case .audioUnitUnavailable: "无法取得 macOS 音频输出单元"
        case let .bindDeviceFailed(status): "绑定指定音箱失败（\(status)）"
        case .defaultDeviceChanged: "系统默认输出在播放期间发生变化"
        case let .playbackFailed(message): "播放失败：\(message)"
        }
    }
}

public struct DeviceAudioPlayer: Sendable {
    private let deviceService: AudioDeviceService

    public init(deviceService: AudioDeviceService = .init()) {
        self.deviceService = deviceService
    }

    public static func clampedVolume(_ value: Double) -> Float32 {
        Float32(min(max(value, 0), 1))
    }

    public func play(
        file: URL,
        through device: AudioOutputDevice,
        volume: Double
    ) async throws {
        let defaultBefore = try deviceService.defaultOutputDeviceID()
        let snapshot = deviceService.setOutputVolume(
            for: device.id,
            to: Self.clampedVolume(volume)
        )
        defer { deviceService.restoreOutputVolume(snapshot, for: device.id) }

        let engine = AVAudioEngine()
        let node = AVAudioPlayerNode()
        guard let unit = engine.outputNode.audioUnit else {
            throw DeviceAudioPlayerError.audioUnitUnavailable
        }
        var id = device.id
        let status = AudioUnitSetProperty(
            unit,
            kAudioOutputUnitProperty_CurrentDevice,
            kAudioUnitScope_Global,
            0,
            &id,
            UInt32(MemoryLayout<AudioDeviceID>.size)
        )
        guard status == noErr else { throw DeviceAudioPlayerError.bindDeviceFailed(status) }

        do {
            let audio = try AVAudioFile(forReading: file)
            engine.attach(node)
            engine.connect(node, to: engine.outputNode, format: audio.processingFormat)
            engine.mainMixerNode.outputVolume = 1
            node.volume = 1
            engine.prepare()
            try engine.start()
            defer { node.stop(); engine.stop() }
            await withCheckedContinuation { continuation in
                node.scheduleFile(audio, at: nil, completionCallbackType: .dataPlayedBack) { _ in
                    continuation.resume()
                }
                node.play()
            }
        } catch {
            throw DeviceAudioPlayerError.playbackFailed(error.localizedDescription)
        }

        guard try deviceService.defaultOutputDeviceID() == defaultBefore else {
            throw DeviceAudioPlayerError.defaultDeviceChanged
        }
    }
}
