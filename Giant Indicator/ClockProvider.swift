//
//  ClockProvider.swift
//  Giant Indicator
//

import Combine
import Foundation

protocol ClockStateProviding {
    func clockStatePublisher(showsSeconds: Bool) -> AnyPublisher<ClockState, Never>
}

struct SystemClockProvider: ClockStateProviding {
    private let processInfo: ProcessInfo
    private let now: () -> Date
    private let inCalendar: Calendar
    private let locale: Locale

    init(
        processInfo: ProcessInfo = .processInfo,
        now: @escaping () -> Date = Date.init,
        calendar inCalendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.processInfo = processInfo
        self.now = now
        self.inCalendar = inCalendar
        self.locale = locale
    }

    func clockStatePublisher(showsSeconds: Bool) -> AnyPublisher<ClockState, Never> {
        if let overrideState = makeUITestOverrideState() {
            return Just(overrideState).eraseToAnyPublisher()
        }

        return Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .map { _ in
                snapshot(showsSeconds: showsSeconds)
            }
            .prepend(snapshot(showsSeconds: showsSeconds))
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private func snapshot(showsSeconds: Bool) -> ClockState {
        ClockState.current(
            at: now(),
            showsSeconds: showsSeconds,
            calendar: inCalendar,
            locale: locale
        )
    }

    private func makeUITestOverrideState() -> ClockState? {
        guard
            let argumentIndex = processInfo.arguments.firstIndex(of: "--ui-testing-clock-time"),
            processInfo.arguments.indices.contains(argumentIndex + 1)
        else {
            return nil
        }

        return ClockState(timeText: processInfo.arguments[argumentIndex + 1])
    }
}
