//
//  BatteryIndicatorTile.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct BatteryIndicatorTile: View {
    @Environment(\.dashboardPalette) private var palette
    @ObservedObject var viewModel: BatteryViewModel
    let metrics: TileMetrics

    private var batteryState: BatteryState { viewModel.state }

    var body: some View {
        VStack(spacing: metrics.contentSpacing) {
            percentageSection

            if batteryState.isDataAvailable {
                BatteryIcon(level: batteryState.normalizedLevel, isPluggedIn: batteryState.isPluggedIn)
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
                .foregroundStyle(palette.titleText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if batteryState.isDataAvailable {
                Text(batteryState.powerConnectionText)
                    .font(.system(size: metrics.subtitleFontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.subtitleText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("battery-power-connection-label")
            }
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
                .foregroundStyle(palette.foreground)
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
            return "Battery \(batteryState.percentageText), \(batteryState.powerConnectionText)"
        }
        if batteryState.unavailableReasonText.isEmpty {
            return "Battery unavailable"
        }
        return "Battery unavailable, \(batteryState.unavailableReasonText)"
    }
}
