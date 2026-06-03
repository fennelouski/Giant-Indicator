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
    var showsKindLabel: Bool = true

    private var batteryState: BatteryState { viewModel.state }

    private var levelColor: Color {
        BatteryAppearance.levelColor(for: batteryState.percentage)
    }

    private var fillColor: Color {
        BatteryAppearance.fillColor(
            percentage: batteryState.percentage,
            chargingState: batteryState.chargingState
        )
    }

    private var accentColor: Color {
        BatteryAppearance.accentColor(
            for: batteryState.chargingState,
            percentage: batteryState.percentage
        )
    }

    var body: some View {
        VStack(spacing: metrics.contentSpacing) {
            percentageSection

            if batteryState.isDataAvailable {
                BatteryIcon(
                    level: batteryState.normalizedLevel,
                    fillColor: fillColor,
                    accentColor: accentColor,
                    isPluggedIn: batteryState.isPluggedIn
                )
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

            if batteryState.isDataAvailable {
                Text(batteryState.chargingStateText)
                    .font(.system(size: metrics.titleFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .accessibilityIdentifier("battery-status-label")
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
                .foregroundStyle(levelColor)
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
            return "Battery \(batteryState.percentageText), \(batteryState.chargingStateText)"
        }
        if batteryState.unavailableReasonText.isEmpty {
            return "Battery unavailable"
        }
        return "Battery unavailable, \(batteryState.unavailableReasonText)"
    }
}
