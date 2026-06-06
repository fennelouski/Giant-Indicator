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
            GeometryReader { proxy in
                let availableWidth = max(proxy.size.width, 0)
                let fontSize = ClockTypography.fittedFontSize(
                    text: clockState.timeText,
                    maxFontSize: metrics.clockTimeFontSize,
                    availableWidth: availableWidth
                )
                Text(clockState.timeText)
                    .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(palette.foreground)
                    .lineLimit(1)
                    .frame(width: availableWidth, alignment: .center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityIdentifier("clock-time-label")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(metrics.padding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Time, \(clockState.timeText)")
        .accessibilityIdentifier("indicator-tile-clock")
        .dashboardTileContainer(cornerRadius: metrics.cornerRadius)
    }
}
