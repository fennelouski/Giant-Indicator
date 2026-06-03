//
//  BatteryReflectiveBackground.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/3/26.
//

import SwiftUI

/// Maps battery level to dashboard background brightness (PR-21).
enum BatteryReflectiveBackground {
    static let lowBatteryThreshold = 10
    static let fullBatteryPercentage = 100

    /// Background brightness in `0...1`. Black below 10%, white at 100%, linear between.
    static func brightness(forPercentage percentage: Int) -> Double {
        let clamped = Swift.min(Swift.max(percentage, 0), fullBatteryPercentage)
        if clamped < lowBatteryThreshold {
            return 0
        }
        if clamped >= fullBatteryPercentage {
            return 1
        }
        let span = Double(fullBatteryPercentage - lowBatteryThreshold)
        let offset = Double(clamped - lowBatteryThreshold)
        return offset / span
    }

    static func backgroundColor(forPercentage percentage: Int) -> Color {
        Color(white: brightness(forPercentage: percentage))
    }
}
