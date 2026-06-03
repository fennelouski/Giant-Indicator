//
//  PlaybackIndicatorTile.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct PlaybackIndicatorTile: View {
    @Environment(\.dashboardPalette) private var palette
    let playbackState: PlaybackState
    let metrics: TileMetrics

    var body: some View {
        VStack(spacing: metrics.contentSpacing) {
            if playbackState.isDataAvailable {
                Image(systemName: playbackState.symbolName)
                    .font(.system(size: metrics.symbolFontSize, weight: .bold))
                    .foregroundStyle(palette.foreground)
                    .frame(height: metrics.iconHeight)
                    .padding(.horizontal, 8)
                    .accessibilityHidden(true)
            } else {
                IndicatorUnavailableGlyph(
                    symbolName: playbackState.unavailableSymbolName,
                    metrics: metrics
                )
            }

            if playbackState.isDataAvailable {
                Text(playbackState.titleText)
                    .font(.system(size: metrics.valueFontSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(palette.foreground)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .accessibilityIdentifier("playback-state-label")
            } else {
                IndicatorUnavailableValueCluster(
                    reason: playbackState.unavailableReasonText,
                    metrics: metrics,
                    valueAccessibilityIdentifier: "playback-state-label",
                    reasonAccessibilityIdentifier: "playback-subtitle-label"
                )
            }

            if playbackState.isDataAvailable {
                Text(playbackState.subtitleText)
                    .font(.system(size: metrics.subtitleFontSize, weight: .medium, design: .rounded))
                    .foregroundStyle(palette.subtitleText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("playback-subtitle-label")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(metrics.padding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(playbackAccessibilityLabel)
        .accessibilityIdentifier("indicator-tile-playback")
        .dashboardTileContainer(cornerRadius: metrics.cornerRadius)
    }

    private var playbackAccessibilityLabel: String {
        if playbackState.isDataAvailable {
            return "Playback, \(playbackState.titleText), \(playbackState.subtitleText)"
        }
        if playbackState.unavailableReasonText.isEmpty {
            return "Playback unavailable"
        }
        return "Playback unavailable, \(playbackState.unavailableReasonText)"
    }
}
