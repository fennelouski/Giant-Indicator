import SwiftUI

struct WiFiIndicatorTile: View {
    @Environment(\.dashboardPalette) private var palette
    let wifiState: WiFiIndicatorState
    let metrics: TileMetrics

    var body: some View {
        VStack(spacing: metrics.contentSpacing) {
            if wifiState.isDataAvailable {
                wifiGlyph
            } else {
                IndicatorUnavailableGlyph(
                    symbolName: wifiState.unavailableSymbolName,
                    metrics: metrics
                )
            }

            if wifiState.isDataAvailable {
                Text(wifiState.primaryValueText)
                    .font(.system(size: metrics.valueFontSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(palette.foreground)
                    .minimumScaleFactor(0.6)
                    .lineLimit(wifiState.displaysNetworkNameAsPrimary ? 2 : 1)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("wifi-value-label")

                if wifiState.showsSubtitle {
                    Text(wifiState.subtitleText)
                        .font(.system(size: metrics.subtitleFontSize, weight: .medium, design: .rounded))
                        .foregroundStyle(palette.subtitleText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .accessibilityIdentifier("wifi-subtitle-label")
                }
            } else {
                IndicatorUnavailableValueCluster(
                    reason: wifiState.unavailableReasonText,
                    metrics: metrics,
                    valueAccessibilityIdentifier: "wifi-value-label",
                    reasonAccessibilityIdentifier: "wifi-subtitle-label"
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(metrics.padding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(wifiState.accessibilitySummary)
        .accessibilityIdentifier("indicator-tile-wifi")
        .dashboardTileContainer(cornerRadius: metrics.cornerRadius)
    }

    @ViewBuilder
    private var wifiGlyph: some View {
        if wifiState.showsSignalStrength {
            GeometryReader { proxy in
                let iconAreaWidth = proxy.size.width * 0.34
                let barAreaWidth = max(0, proxy.size.width - iconAreaWidth - 16)

                HStack(spacing: 16) {
                    Image(systemName: wifiState.symbolName)
                        .font(.system(size: max(26, proxy.size.height * 0.5), weight: .bold))
                        .foregroundStyle(palette.foreground)
                        .frame(width: iconAreaWidth, alignment: .leading)

                    WiFiSignalBars(
                        filledBarCount: wifiState.filledBarCount,
                        isActive: wifiState.isConnected
                    )
                    .frame(width: barAreaWidth, height: max(18, proxy.size.height * 0.28))
                }
            }
            .frame(height: metrics.iconHeight)
            .padding(.horizontal, 8)
        } else {
            Image(systemName: wifiState.symbolName)
                .font(.system(size: metrics.symbolFontSize, weight: .bold))
                .foregroundStyle(palette.foreground)
                .frame(height: metrics.iconHeight)
                .padding(.horizontal, 8)
                .accessibilityHidden(true)
        }
    }
}
