import Combine
import Foundation

@MainActor
final class BatteryViewModel: ObservableObject {
    @Published private(set) var state: BatteryState = .unavailable

    private let provider: BatteryStateProviding
    private var cancellables = Set<AnyCancellable>()

    init(provider: BatteryStateProviding = SystemBatteryProvider()) {
        self.provider = provider
        observe()
    }

    private func observe() {
        provider.batteryStatePublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.state = state
            }
            .store(in: &cancellables)
    }
}
