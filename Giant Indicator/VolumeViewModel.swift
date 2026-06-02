import Combine
import Foundation

@MainActor
final class VolumeViewModel: ObservableObject {
    @Published private(set) var state: VolumeState = .unavailable

    private let provider: VolumeStateProviding
    private var cancellables = Set<AnyCancellable>()

    init(provider: VolumeStateProviding = SystemVolumeProvider()) {
        self.provider = provider
        observe()
    }

    private func observe() {
        provider.volumeStatePublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.state = state
            }
            .store(in: &cancellables)
    }
}
