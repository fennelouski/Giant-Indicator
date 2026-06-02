//
//  VolumeIndicatorTile.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct VolumeIndicatorTile: View {
    let volumeState: VolumeState

    var body: some View {
        VStack(spacing: 20) {
            VolumeIcon(level: volumeState.normalizedLevel, symbolName: volumeState.symbolName)
                .frame(height: 82)
                .padding(.horizontal, 8)

            if volumeState.isAvailable {
                Text(volumeState.percentageText)
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .accessibilityIdentifier("volume-percentage-label")
            } else {
                Text("--")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("volume-percentage-label")

                Text(volumeState.unavailableReason)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("volume-unavailable-label")
            }

            Text("Volume")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .accessibilityIdentifier("indicator-tile-volume")
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
