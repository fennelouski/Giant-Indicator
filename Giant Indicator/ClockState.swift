//
//  ClockState.swift
//  Giant Indicator
//

import Foundation

struct ClockState: Equatable {
    let timeText: String

    static func current(
        at date: Date = Date(),
        showsSeconds: Bool = false,
        calendar inCalendar: Calendar = .current,
        locale: Locale = .current
    ) -> ClockState {
        ClockState(
            timeText: ClockFormatting.timeText(
                from: date,
                showsSeconds: showsSeconds,
                calendar: inCalendar,
                locale: locale
            )
        )
    }
}

enum ClockFormatting {
    static func timeText(
        from date: Date,
        showsSeconds: Bool,
        calendar inCalendar: Calendar = .current,
        locale: Locale = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = inCalendar
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate(showsSeconds ? "jms" : "jm")
        return formatter.string(from: date)
    }
}
