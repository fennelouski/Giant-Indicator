import Combine
import Foundation

#if canImport(AVFoundation)
import AVFoundation
#endif
#if os(macOS)
import CoreAudio
#endif

protocol VolumeStateProviding {
    func volumeStatePublisher() -> AnyPublisher<VolumeState, Never>
}

struct SystemVolumeProvider: VolumeStateProviding {
    private let processInfo: ProcessInfo

    init(processInfo: ProcessInfo = .processInfo) {
        self.processInfo = processInfo
    }

    func volumeStatePublisher() -> AnyPublisher<VolumeState, Never> {
        if let overrideState = makeUITestOverrideState() {
            return Just(overrideState).eraseToAnyPublisher()
        }

        #if os(macOS)
        return Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .map { _ in snapshotMacVolumeState() }
            .prepend(snapshotMacVolumeState())
            .removeDuplicates()
            .eraseToAnyPublisher()
        #elseif canImport(AVFoundation)
        let session = AVAudioSession.sharedInstance()

        return Just(snapshotState(from: session))
            .merge(
                with: session.publisher(for: \.outputVolume)
                    .map { _ in snapshotState(from: session) }
            )
            .removeDuplicates()
            .eraseToAnyPublisher()
        #else
        return Just(
            VolumeState(
                percentage: 0,
                availability: .unavailable(reason: "Unsupported")
            )
        )
        .eraseToAnyPublisher()
        #endif
    }

    private func makeUITestOverrideState() -> VolumeState? {
        guard
            let argumentIndex = processInfo.arguments.firstIndex(of: "--ui-testing-volume-level"),
            processInfo.arguments.indices.contains(argumentIndex + 1),
            let level = Int(processInfo.arguments[argumentIndex + 1])
        else {
            return nil
        }

        return VolumeState(
            percentage: level,
            availability: .available
        )
    }
}

#if canImport(AVFoundation) && !os(macOS)
private func snapshotState(from session: AVAudioSession) -> VolumeState {
    let percentage = Int((session.outputVolume * 100).rounded())
    return VolumeState(
        percentage: percentage,
        availability: .available
    )
}
#endif

enum VolumeSnapshotResolver {
    static func state(masterVolume: Float32?, channelVolumes: [Float32], isMuted: Bool) -> VolumeState {
        if isMuted {
            return VolumeState(percentage: 0, availability: .available)
        }

        let level: Float32
        if let masterVolume, masterVolume.isFinite {
            level = masterVolume
        } else {
            let finiteChannels = channelVolumes.filter(\.isFinite)
            guard !finiteChannels.isEmpty else {
                return VolumeState(
                    percentage: 0,
                    availability: .unavailable(reason: "Volume unavailable for this output")
                )
            }
            level = finiteChannels.reduce(0) { $0 + min(max($1, 0), 1) } / Float32(finiteChannels.count)
        }
        return VolumeState(
            percentage: Int((min(max(level, 0), 1) * 100).rounded()),
            availability: .available
        )
    }
}

#if os(macOS)
private func snapshotMacVolumeState() -> VolumeState {
    var device = AudioDeviceID(kAudioObjectUnknown)
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    guard AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device
    ) == noErr, device != kAudioObjectUnknown else {
        return .unavailable
    }

    var muted: UInt32 = 0
    var muteAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyMute,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain
    )
    var muteSize = UInt32(MemoryLayout<UInt32>.size)
    let hasMute = AudioObjectGetPropertyData(device, &muteAddress, 0, nil, &muteSize, &muted) == noErr

    let masterVolume = readMacVolume(device: device, channel: kAudioObjectPropertyElementMain)
    let channelVolumes = masterVolume == nil ? [1, 2].compactMap {
        readMacVolume(device: device, channel: AudioObjectPropertyElement($0))
    } : []
    return VolumeSnapshotResolver.state(
        masterVolume: masterVolume,
        channelVolumes: channelVolumes,
        isMuted: hasMute && muted != 0
    )
}

private func readMacVolume(device: AudioDeviceID, channel: AudioObjectPropertyElement) -> Float32? {
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyVolumeScalar,
        mScope: kAudioObjectPropertyScopeOutput,
        mElement: channel
    )
    var value: Float32 = 0
    var size = UInt32(MemoryLayout<Float32>.size)
    guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr else { return nil }
    return value
}
#endif
