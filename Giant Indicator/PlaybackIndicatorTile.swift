//
//  PlaybackIndicatorTile.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct PlaybackIndicatorTile: View {
    let playbackState: PlaybackState

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: playbackState.symbolName)
                .font(.system(size: 68, weight: .bold))
                .foregroundStyle(.white)
                .frame(height: 82)
                .padding(.horizontal, 8)
                .accessibilityHidden(true)

            Text(playbackState.titleText)
                .font(.system(size: 52, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityIdentifier("playback-state-label")

            Text("Playback")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)

            Text(playbackState.subtitleText)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier("playback-subtitle-label")
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .accessibilityIdentifier("indicator-tile-playback")
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
