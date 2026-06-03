//
//  VolumeIndicatorTile.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct VolumeIndicatorTile: View {
    @Environment(\.dashboardPalette) private var palette
    let volumeState: VolumeState
    let metrics: TileMetrics

    var body: some View {
        VStack(spacing: metrics.contentSpacing) {
            if volumeState.isDataAvailable {
                VolumeIcon(level: volumeState.normalizedLevel, symbolName: volumeState.symbolName)
                    .frame(height: metrics.iconHeight)
                    .padding(.horizontal, 8)
            } else {
                IndicatorUnavailableGlyph(
                    symbolName: volumeState.unavailableSymbolName,
                    metrics: metrics
                )
            }

            if volumeState.isDataAvailable {
                Text(volumeState.percentageText)
                    .font(.system(size: metrics.valueFontSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(palette.foreground)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .accessibilityIdentifier("volume-percentage-label")
            } else {
                IndicatorUnavailableValueCluster(
                    reason: volumeState.unavailableReasonText,
                    metrics: metrics,
                    valueAccessibilityIdentifier: "volume-percentage-label",
                    reasonAccessibilityIdentifier: "volume-unavailable-label"
                )
            }

            Text("Volume")
                .font(.system(size: metrics.titleFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.titleText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(metrics.padding)
        .accessibilityIdentifier("indicator-tile-volume")
        .dashboardTileContainer(cornerRadius: metrics.cornerRadius)
    }
}
