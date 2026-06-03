//
//  DateViewModel.swift
//  Giant Indicator
//

import Combine
import Foundation

@MainActor
final class DateViewModel: ObservableObject {
    @Published private(set) var state: DateState = .current()

    private let provider: DateStateProviding
    private var cancellables = Set<AnyCancellable>()

    init(provider: DateStateProviding = SystemDateProvider()) {
        self.provider = provider
        observe()
    }

    private func observe() {
        provider.dateStatePublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self, self.state != state else { return }
                self.state = state
            }
            .store(in: &cancellables)
    }
}
