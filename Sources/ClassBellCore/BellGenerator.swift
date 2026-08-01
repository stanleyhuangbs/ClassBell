import AVFoundation
import Foundation

public struct BellGenerator: Sendable {
    public init() {}

    public func createIfNeeded(at url: URL) throws {
        if let size = try? FileManager.default.attributesOfItem(
            atPath: url.path
        )[.size] as? NSNumber, size.intValue > 10_000 {
            return
        }
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let sampleRate = 44_100.0
        let duration = 2.2
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 2,
            interleaved: false
        ), let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ), let channels = buffer.floatChannelData else {
            throw DeviceAudioPlayerError.playbackFailed("无法生成默认铃声")
        }
        buffer.frameLength = frameCount
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let sample = strike(time: time, start: 0)
                + strike(time: time, start: 0.72)
            let softened = Float(tanh(sample * 0.72) * 0.72)
            channels[0][frame] = softened
            channels[1][frame] = softened
        }
        var fileSettings = format.settings
        fileSettings[AVLinearPCMIsNonInterleaved] = false
        let file = try AVAudioFile(forWriting: url, settings: fileSettings)
        try file.write(from: buffer)
    }

    private func strike(time: Double, start: Double) -> Double {
        let t = time - start
        guard t >= 0, t < 1.45 else { return 0 }
        let envelope = (1 - exp(-t * 48)) * exp(-t * 3.25)
        let shimmer = sin(2 * .pi * 880 * t)
            + 0.52 * sin(2 * .pi * 1_320 * t)
            + 0.24 * sin(2 * .pi * 1_760 * t)
        return envelope * shimmer
    }
}
