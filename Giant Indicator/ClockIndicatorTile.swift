//
//  ClockIndicatorTile.swift
//  Giant Indicator
//

import SwiftUI

struct ClockIndicatorTile: View {
    @Environment(\.dashboardPalette) private var palette
    let clockState: ClockState
    let metrics: TileMetrics

    var body: some View {
        VStack(spacing: metrics.contentSpacing) {
            Text(clockState.timeText)
                .font(.system(size: metrics.clockTimeFontSize, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(palette.foreground)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .accessibilityIdentifier("clock-time-label")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(metrics.padding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Time, \(clockState.timeText)")
        .accessibilityIdentifier("indicator-tile-clock")
        .dashboardTileContainer(cornerRadius: metrics.cornerRadius)
    }
}
