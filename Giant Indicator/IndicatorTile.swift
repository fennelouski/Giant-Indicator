//
//  IndicatorTile.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct IndicatorTile: View {
    let placeholder: IndicatorPlaceholder

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: placeholder.symbol)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(.white)

            Text(placeholder.value)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityIdentifier("\(placeholder.kind.rawValue)-value-label")

            Text(placeholder.title)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let subtitle = placeholder.subtitle {
                Text(subtitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("\(placeholder.kind.rawValue)-subtitle-label")
            }

            if let attribution = placeholder.attribution {
                WeatherAttributionView(attribution: attribution)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .accessibilityIdentifier("indicator-tile-\(placeholder.kind.rawValue)")
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
