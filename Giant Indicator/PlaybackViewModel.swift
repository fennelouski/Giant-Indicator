import Combine
import Foundation

@MainActor
final class PlaybackViewModel: ObservableObject {
    @Published private(set) var state: PlaybackState = .unavailable

    private let provider: PlaybackStateProviding
    private var cancellables = Set<AnyCancellable>()

    init(provider: PlaybackStateProviding = SystemPlaybackProvider()) {
        self.provider = provider
        observe()
    }

    private func observe() {
        provider.playbackStatePublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.state = state
            }
            .store(in: &cancellables)
    }
}
