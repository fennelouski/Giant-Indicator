import Combine
import Foundation

@MainActor
final class BatteryViewModel: ObservableObject {
    @Published private(set) var state: BatteryState = .unavailable

    private let provider: BatteryStateProviding
    private var cancellables = Set<AnyCancellable>()

    init(provider: BatteryStateProviding? = nil) {
        self.provider = provider ?? SystemBatteryProvider()
        observe()
    }

    private func observe() {
        provider.batteryStatePublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self, self.state != state else { return }
                self.state = state
            }
            .store(in: &cancellables)
    }
}
