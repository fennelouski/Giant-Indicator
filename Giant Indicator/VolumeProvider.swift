import Combine
import Foundation

#if canImport(AVFoundation)
import AVFoundation
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

        #if canImport(AVFoundation)
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setActive(true, options: [])
        } catch {
            return Just(
                VolumeState(
                    percentage: 0,
                    availability: .unavailable(reason: "Audio Session Error")
                )
            )
            .eraseToAnyPublisher()
        }

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

#if canImport(AVFoundation)
private func snapshotState(from session: AVAudioSession) -> VolumeState {
    let percentage = Int((session.outputVolume * 100).rounded())
    return VolumeState(
        percentage: percentage,
        availability: .available
    )
}
#endif
