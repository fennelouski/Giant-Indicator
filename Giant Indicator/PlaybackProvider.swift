import Combine
import Foundation

#if canImport(AVFoundation)
import AVFoundation
#endif

#if canImport(MediaPlayer)
import MediaPlayer
#endif

#if canImport(UIKit)
import UIKit
#endif

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

        #if canImport(MediaPlayer) && canImport(AVFoundation)
        let notificationCenter = NotificationCenter.default

        var publishers = [AnyPublisher<PlaybackState, Never>]()

        #if canImport(UIKit)
        publishers.append(
            notificationCenter.publisher(for: UIApplication.didBecomeActiveNotification)
                .map { _ in snapshotPlaybackState() }
                .eraseToAnyPublisher()
        )
        #endif

        publishers.append(
            notificationCenter.publisher(for: AVAudioSession.interruptionNotification)
                .map { _ in snapshotPlaybackState() }
                .eraseToAnyPublisher()
        )

        publishers.append(
            notificationCenter.publisher(for: AVAudioSession.routeChangeNotification)
                .map { _ in snapshotPlaybackState() }
                .eraseToAnyPublisher()
        )

        // Some playback transitions do not emit reliable public notifications.
        // A low-frequency poll closes those gaps without driving high CPU usage.
        publishers.append(
            Timer.publish(every: 2, on: .main, in: .common)
                .autoconnect()
                .map { _ in snapshotPlaybackState() }
                .eraseToAnyPublisher()
        )

        let merged = Publishers.MergeMany(publishers)
            .eraseToAnyPublisher()

        return Just(snapshotPlaybackState())
            .merge(with: merged)
            .removeDuplicates()
            .eraseToAnyPublisher()
        #else
        return Just(
            PlaybackState(status: .unavailable(reason: "Unsupported"))
        )
        .eraseToAnyPublisher()
        #endif
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

#if canImport(MediaPlayer)
private func snapshotPlaybackState() -> PlaybackState {
    let nowPlayingCenter = MPNowPlayingInfoCenter.default()
    let nowPlayingInfo = nowPlayingCenter.nowPlayingInfo

    if #available(iOS 13.0, macOS 10.15, *) {
        switch nowPlayingCenter.playbackState {
        case .playing:
            return PlaybackState(status: .playing)
        case .paused, .interrupted:
            return PlaybackState(status: .paused)
        case .stopped:
            // Keep going: some sources report stopped while still publishing metadata.
            break
        @unknown default:
            break
        }
    }

    guard let nowPlayingInfo else {
        return .stopped
    }

    let playbackRate = (nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] as? NSNumber)?.doubleValue
    let defaultPlaybackRate = (nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] as? NSNumber)?.doubleValue ?? 1
    let hasElapsedTime = nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] != nil

    let hasMetadata =
        nowPlayingInfo[MPMediaItemPropertyTitle] != nil ||
        nowPlayingInfo[MPMediaItemPropertyArtist] != nil ||
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] != nil ||
        nowPlayingInfo[MPMediaItemPropertyMediaType] != nil ||
        nowPlayingInfo[MPNowPlayingInfoPropertyExternalContentIdentifier] != nil ||
        nowPlayingInfo[MPNowPlayingInfoPropertyAssetURL] != nil

    if let playbackRate {
        if playbackRate > 0.01 {
            return PlaybackState(status: .playing)
        }

        if hasMetadata || hasElapsedTime {
            return PlaybackState(status: .paused)
        }

        return .stopped
    }

    // If the app provides metadata and timing without a current playback rate,
    // treat this as a paused media session rather than an active playback.
    if hasMetadata || (defaultPlaybackRate > 0 && hasElapsedTime) {
        return PlaybackState(status: .paused)
    }

    return .stopped
}
#endif
