//
//  BatteryAppearance.swift
//  Giant Indicator
//

import SwiftUI

/// Semantic colors for battery level and power source (visible on monochrome dashboard tiles).
enum BatteryAppearance {
    static let lowLevelThreshold = 20
    static let criticalLevelThreshold = 10

    static func levelColor(for percentage: Int) -> Color {
        let clamped = Swift.min(Swift.max(percentage, 0), 100)
        if clamped < criticalLevelThreshold {
            return Color(red: 1, green: 0.23, blue: 0.19)
        }
        if clamped < lowLevelThreshold {
            return Color(red: 1, green: 0.8, blue: 0)
        }
        return Color(red: 0.2, green: 0.78, blue: 0.35)
    }

    static func fillColor(percentage: Int, chargingState: BatteryChargingState) -> Color {
        if chargingState == .charging {
            return levelColor(for: 100)
        }
        return levelColor(for: percentage)
    }

    static func accentColor(for chargingState: BatteryChargingState, percentage: Int) -> Color {
        switch chargingState {
        case .onBattery:
            return levelColor(for: percentage)
        case .charging:
            return levelColor(for: 100)
        case .pluggedNotCharging:
            return Color(red: 0.35, green: 0.72, blue: 1)
        }
    }
}
