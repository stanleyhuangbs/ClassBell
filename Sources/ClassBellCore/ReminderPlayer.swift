import Foundation

public enum ReminderPlayerError: LocalizedError {
    case noDeviceSelected

    public var errorDescription: String? {
        "请先选择蓝牙音箱"
    }
}

public struct ReminderPlayer: Sendable {
    private let deviceService: AudioDeviceService
    private let player: DeviceAudioPlayer
    private let speech: SpeechCache
    private let resolver: ReminderContentResolver
    private let bell: BellGenerator

    public init(
        deviceService: AudioDeviceService = .init(),
        player: DeviceAudioPlayer = .init(),
        speech: SpeechCache = .init(),
        resolver: ReminderContentResolver = .init(),
        bell: BellGenerator = .init()
    ) {
        self.deviceService = deviceService
        self.player = player
        self.speech = speech
        self.resolver = resolver
        self.bell = bell
    }

    public func play(_ reminder: ReminderItem, settings: AppSettings) async throws {
        guard let uid = settings.selectedDeviceUID else {
            throw ReminderPlayerError.noDeviceSelected
        }
        let device = try deviceService.targetDevice(uid: uid)
        let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let bellURL = cache.appendingPathComponent("ClassBell/Bell/double-bell.wav")
        try bell.createIfNeeded(at: bellURL)
        try await player.play(file: bellURL, through: device, volume: settings.volume)
        try await Task.sleep(for: .milliseconds(550))

        let contentURL: URL
        switch try resolver.content(for: reminder) {
        case let .speech(text):
            contentURL = try await speech.render(text: text, id: reminder.id)
        case let .audioFile(url):
            contentURL = url
        }
        try await player.play(file: contentURL, through: device, volume: settings.volume)
    }
}
