//
//  BatteryIndicatorTile.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct BatteryIndicatorTile: View {
    let batteryState: BatteryState

    var body: some View {
        VStack(spacing: 20) {
            BatteryIcon(level: batteryState.normalizedLevel)
                .frame(height: 82)
                .padding(.horizontal, 8)

            if batteryState.isAvailable {
                Text(batteryState.percentageText)
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .accessibilityIdentifier("battery-percentage-label")
            } else {
                Text("--")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("battery-percentage-label")

                Text(batteryState.unavailableReason)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("battery-unavailable-label")
            }

            Text("Battery")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .accessibilityIdentifier("indicator-tile-battery")
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
