//
//  IndicatorFallbackPresentation.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

enum IndicatorFallbackPresentation {
    static let unknownValueText = "--"
}

protocol IndicatorUnavailablePresenting {
    var isDataAvailable: Bool { get }
    var unavailableReasonText: String { get }
    var unavailableSymbolName: String { get }
}

extension IndicatorUnavailablePresenting {
    var unknownValueText: String {
        IndicatorFallbackPresentation.unknownValueText
    }
}

struct IndicatorUnavailableGlyph: View {
    @Environment(\.dashboardPalette) private var palette
    let symbolName: String
    let metrics: TileMetrics
    var iconHeight: CGFloat?

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: metrics.symbolFontSize, weight: .bold))
            .foregroundStyle(palette.mutedText)
            .symbolRenderingMode(.hierarchical)
            .frame(height: iconHeight ?? metrics.iconHeight)
            .padding(.horizontal, 8)
            .accessibilityHidden(true)
    }
}

struct IndicatorUnavailableValueCluster: View {
    @Environment(\.dashboardPalette) private var palette
    let reason: String
    let metrics: TileMetrics
    var valueFontSize: CGFloat?
    let valueAccessibilityIdentifier: String
    let reasonAccessibilityIdentifier: String

    private var resolvedValueFontSize: CGFloat {
        valueFontSize ?? metrics.valueFontSize
    }

    var body: some View {
        Text(IndicatorFallbackPresentation.unknownValueText)
            .font(.system(size: resolvedValueFontSize, weight: .heavy, design: .rounded))
            .foregroundStyle(palette.foreground)
            .accessibilityIdentifier(valueAccessibilityIdentifier)

        Text(reason)
            .font(.system(size: metrics.titleFontSize, weight: .semibold, design: .rounded))
            .foregroundStyle(palette.titleText)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.center)
            .accessibilityIdentifier(reasonAccessibilityIdentifier)
    }
}
