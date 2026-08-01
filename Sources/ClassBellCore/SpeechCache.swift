import AVFoundation
import Foundation

public enum SpeechRenderError: LocalizedError {
    case chineseVoiceUnavailable
    case invalidBuffer

    public var errorDescription: String? {
        switch self {
        case .chineseVoiceUnavailable: "系统没有可用的中文语音"
        case .invalidBuffer: "系统语音生成失败"
        }
    }
}

public struct SpeechCache: Sendable {
    public let directory: URL

    public init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("ClassBell/Speech", isDirectory: true)
    }

    public func render(text: String, id: UUID) async throws -> URL {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let audioURL = directory.appendingPathComponent(id.uuidString).appendingPathExtension("caf")
        let metadataURL = directory.appendingPathComponent(id.uuidString).appendingPathExtension("txt")
        if FileManager.default.fileExists(atPath: audioURL.path),
           (try? String(contentsOf: metadataURL, encoding: .utf8)) == text {
            return audioURL
        }
        try? FileManager.default.removeItem(at: audioURL)
        guard let voice = AVSpeechSynthesisVoice(language: "zh-CN") else {
            throw SpeechRenderError.chineseVoiceUnavailable
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.46
        try await withCheckedThrowingContinuation { continuation in
            let state = SpeechWriteState(url: audioURL, continuation: continuation)
            let synthesizer = AVSpeechSynthesizer()
            state.retain(synthesizer)
            synthesizer.write(utterance) { state.consume($0) }
        }
        try text.write(to: metadataURL, atomically: true, encoding: .utf8)
        return audioURL
    }
}

private final class SpeechWriteState: @unchecked Sendable {
    private let lock = NSLock()
    private let url: URL
    private var continuation: CheckedContinuation<Void, Error>?
    private var file: AVAudioFile?
    private var synthesizer: AVSpeechSynthesizer?
    private var finished = false

    init(url: URL, continuation: CheckedContinuation<Void, Error>) {
        self.url = url
        self.continuation = continuation
    }

    func retain(_ synthesizer: AVSpeechSynthesizer) {
        lock.withLock { self.synthesizer = synthesizer }
    }

    func consume(_ buffer: AVAudioBuffer) {
        lock.withLock {
            guard !finished else { return }
            guard let pcm = buffer as? AVAudioPCMBuffer else {
                finish(.failure(SpeechRenderError.invalidBuffer))
                return
            }
            guard pcm.frameLength > 0 else {
                finish(.success(()))
                return
            }
            do {
                if file == nil {
                    file = try AVAudioFile(forWriting: url, settings: pcm.format.settings)
                }
                try file?.write(from: pcm)
            } catch {
                finish(.failure(error))
            }
        }
    }

    private func finish(_ result: Result<Void, Error>) {
        guard !finished else { return }
        finished = true
        file = nil
        synthesizer = nil
        let pending = continuation
        continuation = nil
        pending?.resume(with: result)
    }
}
