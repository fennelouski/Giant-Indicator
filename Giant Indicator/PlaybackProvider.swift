import Combine
import Foundation

protocol PlaybackStateProviding {
    func playbackStatePublisher() -> AnyPublisher<PlaybackState, Never>
}

struct SystemPlaybackProvider: PlaybackStateProviding {
    private let processInfo: ProcessInfo

    init(processInfo: ProcessInfo = .processInfo) {
        self.processInfo = processInfo
    }

    func playbackStatePublisher() -> AnyPublisher<PlaybackState, Never> {
        if let overrideState = makeUITestOverrideState() {
            return Just(overrideState).eraseToAnyPublisher()
        }

        return Just(
            PlaybackState(status: .unavailable(reason: "Other apps' playback is unavailable"))
        ).eraseToAnyPublisher()
    }

    private func makeUITestOverrideState() -> PlaybackState? {
        guard
            let argumentIndex = processInfo.arguments.firstIndex(of: "--ui-testing-playback-state"),
            processInfo.arguments.indices.contains(argumentIndex + 1)
        else {
            return nil
        }

        let value = processInfo.arguments[argumentIndex + 1].lowercased()
        switch value {
        case "playing":
            return PlaybackState(status: .playing)
        case "paused":
            return PlaybackState(status: .paused)
        case "stopped", "idle":
            return PlaybackState(status: .stopped)
        case "unavailable":
            return PlaybackState(status: .unavailable(reason: "Unavailable"))
        default:
            return PlaybackState(status: .unavailable(reason: "Unknown Override"))
        }
    }
}
