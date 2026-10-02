import Combine
import Foundation

protocol NowPlayingStateProviding {
    func nowPlayingStatePublisher() -> AnyPublisher<NowPlayingState, Never>
}

struct SystemNowPlayingProvider: NowPlayingStateProviding {
    private let processInfo: ProcessInfo

    nonisolated init(processInfo: ProcessInfo = .processInfo) {
        self.processInfo = processInfo
    }

    func nowPlayingStatePublisher() -> AnyPublisher<NowPlayingState, Never> {
        if let overrideState = makeUITestOverrideState() {
            return Just(overrideState).eraseToAnyPublisher()
        }

        return Just(
            NowPlayingState(availability: .unavailable(reason: "Other apps' media is unavailable"))
        ).eraseToAnyPublisher()
    }

    private func makeUITestOverrideState() -> NowPlayingState? {
        if let inactive = makeUITestInactiveOverride() {
            return inactive
        }
        if let unavailable = makeUITestUnavailableOverride() {
            return unavailable
        }
        return makeUITestActiveOverride()
    }

    private func makeUITestInactiveOverride() -> NowPlayingState? {
        guard
            let argumentIndex = processInfo.arguments.firstIndex(of: "--ui-testing-now-playing"),
            processInfo.arguments.indices.contains(argumentIndex + 1),
            processInfo.arguments[argumentIndex + 1].lowercased() == "inactive"
        else {
            return nil
        }
        return .inactive
    }

    private func makeUITestUnavailableOverride() -> NowPlayingState? {
        guard
            let argumentIndex = processInfo.arguments.firstIndex(of: "--ui-testing-now-playing"),
            processInfo.arguments.indices.contains(argumentIndex + 1),
            processInfo.arguments[argumentIndex + 1].lowercased() == "unavailable"
        else {
            return nil
        }
        return .unavailable
    }

    private func makeUITestActiveOverride() -> NowPlayingState? {
        guard let title = uiTestArgumentValue(named: "--ui-testing-now-playing-title") else {
            return nil
        }

        let artist = uiTestArgumentValue(named: "--ui-testing-now-playing-artist")
        let album = uiTestArgumentValue(named: "--ui-testing-now-playing-album")

        return NowPlayingState(
            availability: .active(
                NowPlayingMetadata(
                    title: title,
                    artist: artist,
                    album: album
                )
            )
        )
    }

    private func uiTestArgumentValue(named flag: String) -> String? {
        guard
            let argumentIndex = processInfo.arguments.firstIndex(of: flag),
            processInfo.arguments.indices.contains(argumentIndex + 1)
        else {
            return nil
        }

        let value = processInfo.arguments[argumentIndex + 1].trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
