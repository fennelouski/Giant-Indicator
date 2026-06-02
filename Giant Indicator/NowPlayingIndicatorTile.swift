//
//  NowPlayingIndicatorTile.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct NowPlayingIndicatorTile: View {
    let nowPlayingState: NowPlayingState
    let metrics: TileMetrics

    var body: some View {
        VStack(spacing: metrics.contentSpacing) {
            if nowPlayingState.isDataAvailable {
                Image(systemName: nowPlayingState.symbolName)
                    .font(.system(size: metrics.symbolFontSize, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(height: metrics.iconHeight)
                    .padding(.horizontal, 8)
                    .accessibilityHidden(true)
            } else {
                IndicatorUnavailableGlyph(
                    symbolName: nowPlayingState.unavailableSymbolName,
                    metrics: metrics
                )
            }

            if nowPlayingState.isDataAvailable {
                Text(nowPlayingState.titleText)
                    .font(.system(size: metrics.valueFontSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("now-playing-title-label")
            } else {
                IndicatorUnavailableValueCluster(
                    reason: nowPlayingState.unavailableReasonText,
                    metrics: metrics,
                    valueAccessibilityIdentifier: "now-playing-title-label",
                    reasonAccessibilityIdentifier: "now-playing-unavailable-label"
                )
            }

            Text("Now Playing")
                .font(.system(size: metrics.titleFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let artistText = nowPlayingState.artistText, nowPlayingState.isDataAvailable {
                Text(artistText)
                    .font(.system(size: metrics.subtitleFontSize, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("now-playing-artist-label")
            }

            if let albumText = nowPlayingState.albumText, nowPlayingState.isDataAvailable {
                Text(albumText)
                    .font(.system(size: metrics.subtitleFontSize * 0.9, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("now-playing-album-label")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(metrics.padding)
        .accessibilityIdentifier("indicator-tile-nowPlaying")
        .dashboardTileContainer(cornerRadius: metrics.cornerRadius)
    }
}
