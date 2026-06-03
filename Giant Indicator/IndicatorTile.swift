//
//  IndicatorTile.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct IndicatorTile: View {
    @Environment(\.dashboardPalette) private var palette
    let placeholder: IndicatorPlaceholder
    let metrics: TileMetrics

    var body: some View {
        VStack(spacing: metrics.contentSpacing) {
            if placeholder.showsUnavailableFallback {
                IndicatorUnavailableGlyph(symbolName: placeholder.symbol, metrics: metrics)
            } else {
                Image(systemName: placeholder.symbol)
                    .font(.system(size: metrics.symbolFontSize, weight: .bold))
                    .foregroundStyle(palette.foreground)
            }

            Text(placeholder.value)
                .font(.system(size: metrics.valueFontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(palette.foreground)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("\(placeholder.kind.rawValue)-value-label")

            if let subtitle = placeholder.subtitle {
                Text(subtitle)
                    .font(.system(size: metrics.subtitleFontSize, weight: .medium, design: .rounded))
                    .foregroundStyle(palette.subtitleText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("\(placeholder.kind.rawValue)-subtitle-label")
            }

            if let attribution = placeholder.attribution {
                WeatherAttributionView(attribution: attribution)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(metrics.padding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(weatherAccessibilityLabel)
        .accessibilityIdentifier("indicator-tile-\(placeholder.kind.rawValue)")
        .dashboardTileContainer(cornerRadius: metrics.cornerRadius)
    }

    private var weatherAccessibilityLabel: String {
        if let subtitle = placeholder.subtitle, !subtitle.isEmpty {
            return "\(placeholder.title), \(placeholder.value), \(subtitle)"
        }
        return "\(placeholder.title), \(placeholder.value)"
    }
}
