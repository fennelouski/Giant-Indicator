//
//  ConnectivityIndicatorTile.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct ConnectivityIndicatorTile: View {
    let placeholder: IndicatorPlaceholder
    let metrics: TileMetrics

    var body: some View {
        VStack(spacing: metrics.contentSpacing) {
            if placeholder.showsUnavailableFallback {
                IndicatorUnavailableGlyph(symbolName: placeholder.symbol, metrics: metrics)
            } else {
                Image(systemName: placeholder.symbol)
                    .font(.system(size: metrics.symbolFontSize, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(height: metrics.iconHeight)
                    .padding(.horizontal, 8)
                    .accessibilityHidden(true)
            }

            Text(placeholder.value)
                .font(.system(size: metrics.valueFontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityIdentifier("\(placeholder.kind.rawValue)-value-label")

            Text(placeholder.title)
                .font(.system(size: metrics.titleFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let subtitle = placeholder.subtitle {
                Text(subtitle)
                    .font(.system(size: metrics.subtitleFontSize, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("\(placeholder.kind.rawValue)-subtitle-label")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(metrics.padding)
        .accessibilityIdentifier("indicator-tile-\(placeholder.kind.rawValue)")
        .dashboardTileContainer(cornerRadius: metrics.cornerRadius)
    }
}
