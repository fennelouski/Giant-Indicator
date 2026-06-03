//
//  DateState.swift
//  Giant Indicator
//

import Foundation

struct DateState: Equatable {
    let dateText: String

    static func current(
        at date: Date = Date(),
        calendar inCalendar: Calendar = .current,
        locale: Locale = .current
    ) -> DateState {
        DateState(
            dateText: DateFormatting.dateText(
                from: date,
                calendar: inCalendar,
                locale: locale
            )
        )
    }
}

enum DateFormatting {
    static func dateText(
        from date: Date,
        calendar inCalendar: Calendar = .current,
        locale: Locale = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = inCalendar
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("EEEEMMMMd")
        return formatter.string(from: date)
    }
}
