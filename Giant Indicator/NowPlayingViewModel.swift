import Combine
import Foundation

@MainActor
final class NowPlayingViewModel: ObservableObject {
    @Published private(set) var state: NowPlayingState = .unavailable

    private let provider: NowPlayingStateProviding
    private var cancellables = Set<AnyCancellable>()

    init(provider: NowPlayingStateProviding = SystemNowPlayingProvider()) {
        self.provider = provider
        observe()
    }

    private func observe() {
        provider.nowPlayingStatePublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self, self.state != state else { return }
                self.state = state
            }
            .store(in: &cancellables)
    }
}
