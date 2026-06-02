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
            percentageSection

            if batteryState.isDataAvailable {
                BatteryIcon(level: batteryState.normalizedLevel)
                    .frame(height: metrics.batteryIconHeight)
                    .padding(.horizontal, 8)
                    .accessibilityHidden(true)
            } else {
                IndicatorUnavailableGlyph(
                    symbolName: batteryState.unavailableSymbolName,
                    metrics: metrics,
                    iconHeight: metrics.batteryIconHeight
                )
            }

            Text("Battery")
                .font(.system(size: metrics.titleFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(metrics.padding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("indicator-tile-battery")
        .dashboardTileContainer(cornerRadius: metrics.cornerRadius)
    }

    @ViewBuilder
    private var percentageSection: some View {
        if batteryState.isDataAvailable {
            Text(batteryState.percentageText)
                .font(.system(size: metrics.batteryPercentageFontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .accessibilityIdentifier("battery-percentage-label")
        } else {
            IndicatorUnavailableValueCluster(
                reason: batteryState.unavailableReasonText,
                metrics: metrics,
                valueFontSize: metrics.batteryPercentageFontSize,
                valueAccessibilityIdentifier: "battery-percentage-label",
                reasonAccessibilityIdentifier: "battery-unavailable-label"
            )
        }
    }

    private var accessibilityLabel: String {
        if batteryState.isDataAvailable {
            return "Battery \(batteryState.percentageText)"
        }
        if batteryState.unavailableReasonText.isEmpty {
            return "Battery unavailable"
        }
        return "Battery unavailable, \(batteryState.unavailableReasonText)"
    }
}
