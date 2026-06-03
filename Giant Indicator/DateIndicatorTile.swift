//
//  DateIndicatorTile.swift
//  Giant Indicator
//

import SwiftUI

struct DateIndicatorTile: View {
    @Environment(\.dashboardPalette) private var palette
    let dateState: DateState
    let metrics: TileMetrics

    var body: some View {
        VStack(spacing: metrics.contentSpacing) {
            Text(dateState.dateText)
                .font(.system(size: metrics.dateTextFontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(palette.foreground)
                .minimumScaleFactor(0.4)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("date-text-label")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(metrics.padding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Date, \(dateState.dateText)")
        .accessibilityIdentifier("indicator-tile-date")
        .dashboardTileContainer(cornerRadius: metrics.cornerRadius)
    }
}
