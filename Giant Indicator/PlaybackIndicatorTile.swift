//
//  PlaybackIndicatorTile.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct PlaybackIndicatorTile: View {
    let playbackState: PlaybackState
    let metrics: TileMetrics

    var body: some View {
        VStack(spacing: metrics.contentSpacing) {
            Image(systemName: playbackState.symbolName)
                .font(.system(size: metrics.symbolFontSize, weight: .bold))
                .foregroundStyle(.white)
                .frame(height: metrics.iconHeight)
                .padding(.horizontal, 8)
                .accessibilityHidden(true)

            Text(playbackState.titleText)
                .font(.system(size: metrics.valueFontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityIdentifier("playback-state-label")

            Text("Playback")
                .font(.system(size: metrics.titleFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(playbackState.subtitleText)
                .font(.system(size: metrics.subtitleFontSize, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.86))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier("playback-subtitle-label")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(metrics.padding)
        .accessibilityIdentifier("indicator-tile-playback")
        .dashboardTileContainer(cornerRadius: metrics.cornerRadius)
    }
}
