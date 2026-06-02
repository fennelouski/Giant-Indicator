import Combine
import Foundation

@MainActor
final class ConnectivityViewModel: ObservableObject {
    @Published private(set) var state: ConnectivityState = .unavailable

    private let provider: ConnectivityProviding
    private var cancellables = Set<AnyCancellable>()

    init(provider: ConnectivityProviding = SystemConnectivityProvider()) {
        self.provider = provider
        observe()
    }

    private func observe() {
        provider.connectivityPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.state = newState
            }
            .store(in: &cancellables)
    }
}
