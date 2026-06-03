//
//  ClockViewModel.swift
//  Giant Indicator
//

import Combine
import Foundation

@MainActor
final class ClockViewModel: ObservableObject {
    @Published private(set) var state: ClockState = .current()

    private let provider: ClockStateProviding
    private var showsSeconds: Bool
    private var cancellables = Set<AnyCancellable>()

    init(
        provider: ClockStateProviding? = nil,
        showsSeconds: Bool? = nil
    ) {
        self.provider = provider ?? SystemClockProvider()
        self.showsSeconds = showsSeconds ?? DisplayPreferences.showClockSeconds
        observe()
    }

    func updateShowsSeconds(_ enabled: Bool) {
        guard showsSeconds != enabled else { return }
        showsSeconds = enabled
        cancellables.removeAll()
        state = .current(showsSeconds: enabled)
        observe()
    }

    private func observe() {
        provider.clockStatePublisher(showsSeconds: showsSeconds)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self, self.state != state else { return }
                self.state = state
            }
            .store(in: &cancellables)
    }
}
