//
//  BatteryIndicatorTile.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct BatteryIndicatorTile: View {
    let batteryState: BatteryState
    let metrics: TileMetrics

    var body: some View {
        VStack(spacing: metrics.contentSpacing) {
            BatteryIcon(level: batteryState.normalizedLevel)
                .frame(height: metrics.iconHeight)
                .padding(.horizontal, 8)

            if batteryState.isAvailable {
                Text(batteryState.percentageText)
                    .font(.system(size: metrics.valueFontSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .accessibilityIdentifier("battery-percentage-label")
            } else {
                Text("--")
                    .font(.system(size: metrics.valueFontSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("battery-percentage-label")

                Text(batteryState.unavailableReason)
                    .font(.system(size: metrics.titleFontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("battery-unavailable-label")
            }

            Text("Battery")
                .font(.system(size: metrics.titleFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(metrics.padding)
        .accessibilityIdentifier("indicator-tile-battery")
        .dashboardTileContainer(cornerRadius: metrics.cornerRadius)
    }
}
