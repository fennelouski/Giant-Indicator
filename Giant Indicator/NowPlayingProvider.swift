import Combine
import Foundation

#if canImport(MediaPlayer)
import MediaPlayer
#endif

#if canImport(UIKit)
import UIKit
#endif

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

        #if canImport(MediaPlayer)
        let notificationCenter = NotificationCenter.default
        var publishers = [AnyPublisher<NowPlayingState, Never>]()

        #if canImport(UIKit)
        publishers.append(
            notificationCenter.publisher(for: UIApplication.didBecomeActiveNotification)
                .map { _ in snapshotNowPlayingState() }
                .eraseToAnyPublisher()
        )
        #endif

        publishers.append(
            Timer.publish(every: 2, on: .main, in: .common)
                .autoconnect()
                .map { _ in snapshotNowPlayingState() }
                .eraseToAnyPublisher()
        )

        let merged = Publishers.MergeMany(publishers).eraseToAnyPublisher()

        return Just(snapshotNowPlayingState())
            .merge(with: merged)
            .removeDuplicates()
            .eraseToAnyPublisher()
        #else
        return Just(
            NowPlayingState(availability: .unavailable(reason: "Unsupported"))
        )
        .eraseToAnyPublisher()
        #endif
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

#if canImport(MediaPlayer)
private func snapshotNowPlayingState() -> NowPlayingState {
    guard let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
        return .inactive
    }

    let title = trimmedString(nowPlayingInfo[MPMediaItemPropertyTitle] as? String)
    let artist = trimmedString(nowPlayingInfo[MPMediaItemPropertyArtist] as? String)
    let album = trimmedString(nowPlayingInfo[MPMediaItemPropertyAlbumTitle] as? String)

    guard title != nil || artist != nil || album != nil else {
        return .inactive
    }

    let resolvedTitle: String
    let resolvedArtist: String?

    if let title {
        resolvedTitle = title
        resolvedArtist = artist
    } else if let artist {
        resolvedTitle = artist
        resolvedArtist = nil
    } else if let album {
        resolvedTitle = album
        resolvedArtist = nil
    } else {
        return .inactive
    }

    return NowPlayingState(
        availability: .active(
            NowPlayingMetadata(
                title: resolvedTitle,
                artist: resolvedArtist,
                album: album
            )
        )
    )
}

private func trimmedString(_ value: String?) -> String? {
    guard let value else { return nil }
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
}
#endif
