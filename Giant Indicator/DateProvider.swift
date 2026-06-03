//
//  DateProvider.swift
//  Giant Indicator
//

import Combine
import Foundation

protocol DateStateProviding {
    func dateStatePublisher() -> AnyPublisher<DateState, Never>
}

struct SystemDateProvider: DateStateProviding {
    private let processInfo: ProcessInfo
    private let now: () -> Date
    private let calendar: Calendar
    private let locale: Locale

    init(
        processInfo: ProcessInfo = .processInfo,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.processInfo = processInfo
        self.now = now
        self.calendar = calendar
        self.locale = locale
    }

    func dateStatePublisher() -> AnyPublisher<DateState, Never> {
        if let overrideState = makeUITestOverrideState() {
            return Just(overrideState).eraseToAnyPublisher()
        }

        return Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .map { _ in snapshot() }
            .prepend(snapshot())
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private func snapshot() -> DateState {
        DateState.current(at: now(), calendar: calendar, locale: locale)
    }

    private func makeUITestOverrideState() -> DateState? {
        guard
            let argumentIndex = processInfo.arguments.firstIndex(of: "--ui-testing-date-text"),
            processInfo.arguments.indices.contains(argumentIndex + 1)
        else {
            return nil
        }

        return DateState(dateText: processInfo.arguments[argumentIndex + 1])
    }
}
