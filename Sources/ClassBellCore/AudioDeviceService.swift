import CoreAudio
import Foundation

public struct AudioOutputDevice: @unchecked Sendable, Equatable, Identifiable {
    public let id: AudioDeviceID
    public let uid: String
    public let name: String

    public init(id: AudioDeviceID, uid: String, name: String) {
        self.id = id
        self.uid = uid
        self.name = name
    }
}

public struct AudioDeviceVolumeSnapshot: Sendable {
    public let valuesByElement: [UInt32: Float32]
}

public enum AudioDeviceError: LocalizedError {
    case propertyReadFailed(OSStatus)
    case targetNotFound

    public var errorDescription: String? {
        switch self {
        case let .propertyReadFailed(status): "读取音频设备失败（\(status)）"
        case .targetNotFound: "所选音箱未连接，本次不会改用其他扬声器"
        }
    }
}

public struct AudioDeviceService: Sendable {
    public init() {}

    public static func matching(
        uid: String,
        in devices: [AudioOutputDevice]
    ) -> AudioOutputDevice? {
        devices.first { $0.uid == uid }
    }

    public func outputDevices() throws -> [AudioOutputDevice] {
        let system = AudioObjectID(kAudioObjectSystemObject)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size)
        guard status == noErr else { throw AudioDeviceError.propertyReadFailed(status) }
        var ids = [AudioDeviceID](
            repeating: 0,
            count: Int(size) / MemoryLayout<AudioDeviceID>.size
        )
        status = ids.withUnsafeMutableBytes {
            AudioObjectGetPropertyData(system, &address, 0, nil, &size, $0.baseAddress!)
        }
        guard status == noErr else { throw AudioDeviceError.propertyReadFailed(status) }

        return try ids.compactMap { id in
            guard try outputChannelCount(for: id) > 0 else { return nil }
            return AudioOutputDevice(
                id: id,
                uid: try stringProperty(kAudioDevicePropertyDeviceUID, of: id),
                name: try stringProperty(kAudioObjectPropertyName, of: id)
            )
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public func targetDevice(uid: String) throws -> AudioOutputDevice {
        guard let match = Self.matching(uid: uid, in: try outputDevices()) else {
            throw AudioDeviceError.targetNotFound
        }
        return match
    }

    public func defaultOutputDeviceID() throws -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var id = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &id
        )
        guard status == noErr else { throw AudioDeviceError.propertyReadFailed(status) }
        return id
    }

    public func setOutputVolume(
        for deviceID: AudioDeviceID,
        to requested: Float32
    ) -> AudioDeviceVolumeSnapshot {
        let channelCount = (try? outputChannelCount(for: deviceID)) ?? 0
        let elements = [UInt32(0)] + (channelCount > 0 ? (1...channelCount).map(UInt32.init) : [])
        var values: [UInt32: Float32] = [:]
        for element in elements {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioObjectPropertyScopeOutput,
                mElement: element
            )
            guard AudioObjectHasProperty(deviceID, &address) else { continue }
            var settable = DarwinBoolean(false)
            guard AudioObjectIsPropertySettable(deviceID, &address, &settable) == noErr,
                  settable.boolValue else { continue }
            var original = Float32(0)
            var size = UInt32(MemoryLayout<Float32>.size)
            guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &original) == noErr else { continue }
            var volume = min(max(requested, 0), 1)
            guard AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &volume) == noErr else { continue }
            values[element] = original
        }
        return AudioDeviceVolumeSnapshot(valuesByElement: values)
    }

    public func restoreOutputVolume(
        _ snapshot: AudioDeviceVolumeSnapshot,
        for deviceID: AudioDeviceID
    ) {
        for (element, original) in snapshot.valuesByElement {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioObjectPropertyScopeOutput,
                mElement: element
            )
            var value = original
            let size = UInt32(MemoryLayout<Float32>.size)
            AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &value)
        }
    }

    private func stringProperty(
        _ selector: AudioObjectPropertySelector,
        of id: AudioDeviceID
    ) throws -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var unmanaged: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &unmanaged)
        guard status == noErr, let value = unmanaged?.takeUnretainedValue() else {
            throw AudioDeviceError.propertyReadFailed(status)
        }
        return value as String
    }

    private func outputChannelCount(for id: AudioDeviceID) throws -> Int {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size)
        guard status == noErr else { throw AudioDeviceError.propertyReadFailed(status) }
        let raw = UnsafeMutableRawPointer.allocate(
            byteCount: Int(size),
            alignment: MemoryLayout<AudioBufferList>.alignment
        )
        defer { raw.deallocate() }
        let list = raw.assumingMemoryBound(to: AudioBufferList.self)
        status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, list)
        guard status == noErr else { throw AudioDeviceError.propertyReadFailed(status) }
        return UnsafeMutableAudioBufferListPointer(list).reduce(0) { $0 + Int($1.mNumberChannels) }
    }
}
