//
//  BatteryIndicatorTile.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct BatteryIndicatorTile: View {
    @Environment(\.dashboardPalette) private var palette
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverEnabled
    @ObservedObject var viewModel: BatteryViewModel
    let metrics: TileMetrics
    var showsKindLabel: Bool = true

    @State private var displayStyle: BatteryTileDisplayStyle = DisplayPreferences.batteryTileDisplayStyle

    private var batteryState: BatteryState { viewModel.state }

    private var effectiveStyle: BatteryTileDisplayStyle {
        BatteryTileDisplayStyle.resolvedStyle(preferred: displayStyle, in: metrics)
    }

    private var levelColor: Color {
        BatteryAppearance.levelColor(for: batteryState.percentage)
    }

    private var fillColor: Color {
        BatteryAppearance.fillColor(
            percentage: batteryState.percentage,
            chargingState: batteryState.chargingState
        )
    }

    private var accentColor: Color {
        BatteryAppearance.accentColor(
            for: batteryState.chargingState,
            percentage: batteryState.percentage
        )
    }

    var body: some View {
        Group {
            switch effectiveStyle {
            case .standard:
                standardLayout(animatesLevelChanges: false, chargingPulse: false)
            case .horizontal:
                horizontalLayout
            case .compact:
                compactLayout
            case .iconFocus:
                iconFocusLayout
            case .symbol:
                symbolLayout
            case .animatedBar:
                standardLayout(animatesLevelChanges: true, chargingPulse: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(metrics.padding)
        .animation(.easeInOut(duration: 0.25), value: effectiveStyle)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("indicator-tile-battery")
        .dashboardTileContainer(cornerRadius: metrics.cornerRadius)
    }

    private func standardLayout(animatesLevelChanges: Bool, chargingPulse: Bool) -> some View {
        VStack(spacing: metrics.contentSpacing) {
            tappablePercentageSection(fontSize: metrics.batteryPercentageFontSize)
            batteryGlyphSection(
                height: metrics.batteryIconHeight,
                animatesLevelChanges: animatesLevelChanges,
                chargingPulse: chargingPulse
            )
            if batteryState.isDataAvailable {
                statusSection
            }
        }
    }

    private var horizontalLayout: some View {
        VStack(spacing: metrics.contentSpacing) {
            HStack(alignment: .center, spacing: metrics.contentSpacing) {
                tappablePercentageSection(fontSize: metrics.batteryPercentageFontSize * 0.82)
                    .frame(maxWidth: .infinity, alignment: .leading)
                batteryGlyphSection(
                    height: metrics.batteryIconHeight * 1.1,
                    animatesLevelChanges: false,
                    chargingPulse: false
                )
                .frame(maxWidth: .infinity)
            }
            if batteryState.isDataAvailable && metrics.height >= TileMetrics.minimumReadableTileHeight {
                statusSection
            }
        }
    }

    private var compactLayout: some View {
        VStack {
            Spacer(minLength: 0)
            tappablePercentageSection(fontSize: metrics.batteryPercentageFontSize * 1.08)
            Spacer(minLength: 0)
        }
    }

    private var iconFocusLayout: some View {
        ZStack {
            batteryGlyphSection(
                height: metrics.batteryIconHeight * 1.75,
                animatesLevelChanges: false,
                chargingPulse: false
            )
            .padding(.horizontal, 4)

            VStack {
                Spacer()
                tappablePercentageSection(fontSize: metrics.titleFontSize * 1.05)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(palette.background.opacity(0.72), in: Capsule(style: .continuous))
                    .padding(.bottom, 6)
            }
        }
    }

    private var symbolLayout: some View {
        VStack(spacing: metrics.contentSpacing) {
            if batteryState.isDataAvailable {
                Image(systemName: batteryState.percentageSymbolName)
                    .font(.system(size: metrics.symbolFontSize, weight: .bold))
                    .foregroundStyle(levelColor)
                    .accessibilityHidden(true)
            } else {
                IndicatorUnavailableGlyph(
                    symbolName: batteryState.unavailableSymbolName,
                    metrics: metrics,
                    iconHeight: metrics.symbolFontSize
                )
            }
            tappablePercentageSection(fontSize: metrics.batteryPercentageFontSize * 0.72)
            if batteryState.isDataAvailable {
                statusSection
            }
        }
    }

    @ViewBuilder
    private func batteryGlyphSection(
        height: CGFloat,
        animatesLevelChanges: Bool,
        chargingPulse: Bool
    ) -> some View {
        if batteryState.isDataAvailable {
            BatteryIcon(
                level: batteryState.normalizedLevel,
                fillColor: fillColor,
                accentColor: accentColor,
                isPluggedIn: batteryState.isPluggedIn,
                animatesLevelChanges: animatesLevelChanges,
                chargingPulse: chargingPulse
            )
            .frame(height: height)
            .padding(.horizontal, 8)
            .accessibilityHidden(true)
        } else {
            IndicatorUnavailableGlyph(
                symbolName: batteryState.unavailableSymbolName,
                metrics: metrics,
                iconHeight: height
            )
        }
    }

    private var statusSection: some View {
        Text(batteryState.chargingStateText)
            .font(.system(size: metrics.titleFontSize, weight: .bold, design: .rounded))
            .foregroundStyle(accentColor)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .accessibilityIdentifier("battery-status-label")
    }

    private func tappablePercentageSection(fontSize: CGFloat) -> some View {
        Button(action: cycleDisplayStyle) {
            percentageContent(fontSize: fontSize)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Changes battery display style")
    }

    @ViewBuilder
    private func percentageContent(fontSize: CGFloat) -> some View {
        if batteryState.isDataAvailable {
            Text(batteryState.percentageText)
                .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(levelColor)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText())
                .accessibilityIdentifier("battery-percentage-label")
        } else {
            IndicatorUnavailableValueCluster(
                reason: batteryState.unavailableReasonText,
                metrics: metrics,
                valueFontSize: fontSize,
                valueAccessibilityIdentifier: "battery-percentage-label",
                reasonAccessibilityIdentifier: "battery-unavailable-label"
            )
        }
    }

    private func cycleDisplayStyle() {
        let next = BatteryTileDisplayStyle.next(after: displayStyle, in: metrics)
        displayStyle = next
        DisplayPreferences.batteryTileDisplayStyle = next
        if isVoiceOverEnabled {
            AccessibilityNotification.Announcement(String(localized: "\(next.accessibilityDescription)"))
                .post()
        }
    }

    private var accessibilityLabel: String {
        let styleSuffix = ", \(effectiveStyle.accessibilityDescription)"
        if batteryState.isDataAvailable {
            return "Battery \(batteryState.percentageText), \(batteryState.chargingStateText)\(styleSuffix)"
        }
        if batteryState.unavailableReasonText.isEmpty {
            return "Battery unavailable\(styleSuffix)"
        }
        return "Battery unavailable, \(batteryState.unavailableReasonText)\(styleSuffix)"
    }
}
