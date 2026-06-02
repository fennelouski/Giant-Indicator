//
//  VolumeIndicatorTile.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct VolumeIndicatorTile: View {
    let volumeState: VolumeState
    let metrics: TileMetrics

    var body: some View {
        VStack(spacing: metrics.contentSpacing) {
            VolumeIcon(level: volumeState.normalizedLevel, symbolName: volumeState.symbolName)
                .frame(height: metrics.iconHeight)
                .padding(.horizontal, 8)

            if volumeState.isAvailable {
                Text(volumeState.percentageText)
                    .font(.system(size: metrics.valueFontSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .accessibilityIdentifier("volume-percentage-label")
            } else {
                Text("--")
                    .font(.system(size: metrics.valueFontSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("volume-percentage-label")

                Text(volumeState.unavailableReason)
                    .font(.system(size: metrics.titleFontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("volume-unavailable-label")
            }

            Text("Volume")
                .font(.system(size: metrics.titleFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(metrics.padding)
        .accessibilityIdentifier("indicator-tile-volume")
        .dashboardTileContainer(cornerRadius: metrics.cornerRadius)
    }
}
