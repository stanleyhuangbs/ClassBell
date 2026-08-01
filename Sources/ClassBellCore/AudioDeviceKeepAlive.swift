import AudioToolbox
import AVFoundation

public actor AudioDeviceKeepAlive {
    private var engine: AVAudioEngine?
    private var node: AVAudioPlayerNode?
    private var buffer: AVAudioPCMBuffer?
    private var activeDeviceID: AudioDeviceID?

    public init() {}

    public var isActive: Bool {
        engine?.isRunning == true && node?.isPlaying == true
    }

    public func start(through device: AudioOutputDevice) throws {
        if activeDeviceID == device.id, isActive { return }
        stop()
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
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2),
              let silent = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 44_100) else {
            throw DeviceAudioPlayerError.playbackFailed("无法创建蓝牙保活音频")
        }
        silent.frameLength = silent.frameCapacity
        engine.attach(node)
        engine.connect(node, to: engine.outputNode, format: format)
        node.scheduleBuffer(silent, at: nil, options: .loops)
        engine.prepare()
        try engine.start()
        node.play()
        self.engine = engine
        self.node = node
        self.buffer = silent
        activeDeviceID = device.id
    }

    public func stop() {
        node?.stop()
        engine?.stop()
        node = nil
        engine = nil
        buffer = nil
        activeDeviceID = nil
    }
}
