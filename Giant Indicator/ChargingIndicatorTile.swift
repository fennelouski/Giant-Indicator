//
//  ChargingIndicatorTile.swift
//  Giant Indicator
//

import SwiftUI

struct ChargingIndicatorTile: View {
    @Environment(\.dashboardPalette) private var palette
    @ObservedObject var viewModel: BatteryViewModel
    let metrics: TileMetrics
    var showsKindLabel: Bool = true

    private var batteryState: BatteryState { viewModel.state }

    private var accentColor: Color {
        BatteryAppearance.accentColor(
            for: batteryState.chargingState,
            percentage: batteryState.percentage
        )
    }

    var body: some View {
        VStack(spacing: metrics.contentSpacing) {
            if batteryState.isDataAvailable {
                Image(systemName: batteryState.chargingStateSymbolName)
                    .font(.system(size: metrics.symbolFontSize, weight: .bold))
                    .foregroundStyle(accentColor)
                    .accessibilityIdentifier("charging-state-symbol")
            } else {
                IndicatorUnavailableGlyph(
                    symbolName: batteryState.unavailableSymbolName,
                    metrics: metrics
                )
            }

            if batteryState.isDataAvailable {
                Text(batteryState.chargingStateText)
                    .font(.system(size: metrics.titleFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .accessibilityIdentifier("charging-state-value-label")
            } else {
                IndicatorUnavailableValueCluster(
                    reason: batteryState.unavailableReasonText,
                    metrics: metrics,
                    valueAccessibilityIdentifier: "charging-state-value-label",
                    reasonAccessibilityIdentifier: "charging-state-unavailable-label"
                )
            }

            if showsKindLabel {
                Text(IndicatorKind.chargingState.displayName)
                    .font(.system(size: metrics.titleFontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.titleText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("charging-state-kind-label")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(metrics.padding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("indicator-tile-chargingState")
        .dashboardTileContainer(cornerRadius: metrics.cornerRadius)
    }

    private var accessibilityLabel: String {
        if batteryState.isDataAvailable {
            return "Charging state, \(batteryState.chargingStateText)"
        }
        if batteryState.unavailableReasonText.isEmpty {
            return "Charging state unavailable"
        }
        return "Charging state unavailable, \(batteryState.unavailableReasonText)"
    }
}
