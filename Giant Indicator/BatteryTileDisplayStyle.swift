//
//  BatteryTileDisplayStyle.swift
//  Giant Indicator
//

import Foundation

/// User-selectable presentation for the battery indicator tile (tap percentage to cycle).
enum BatteryTileDisplayStyle: String, CaseIterable, Codable, Equatable {
    case standard
    case horizontal
    case compact
    case iconFocus
    case symbol
    case animatedBar

    /// Ordered list used when cycling styles.
    static let cyclingOrder: [BatteryTileDisplayStyle] = allCases

    var accessibilityDescription: String {
        switch self {
        case .standard:
            return "Standard display"
        case .horizontal:
            return "Horizontal display"
        case .compact:
            return "Compact display"
        case .iconFocus:
            return "Icon focus display"
        case .symbol:
            return "Symbol display"
        case .animatedBar:
            return "Animated bar display"
        }
    }

    func fits(in metrics: TileMetrics) -> Bool {
        switch self {
        case .standard, .animatedBar:
            return metrics.height >= TileMetrics.minimumReadableTileHeight
        case .horizontal:
            return metrics.width >= 200 && metrics.height >= 110
        case .compact:
            return metrics.height >= 80
        case .iconFocus:
            return metrics.height >= 150
        case .symbol:
            return metrics.height >= 110
        }
    }

    static func eligibleStyles(for metrics: TileMetrics) -> [BatteryTileDisplayStyle] {
        cyclingOrder.filter { $0.fits(in: metrics) }
    }

    static func resolvedStyle(preferred: BatteryTileDisplayStyle, in metrics: TileMetrics) -> BatteryTileDisplayStyle {
        let eligible = eligibleStyles(for: metrics)
        if preferred.fits(in: metrics) {
            return preferred
        }
        return eligible.first ?? .standard
    }

    static func next(after current: BatteryTileDisplayStyle, in metrics: TileMetrics) -> BatteryTileDisplayStyle {
        let eligible = eligibleStyles(for: metrics)
        guard !eligible.isEmpty else { return .standard }
        guard let index = eligible.firstIndex(of: current) else {
            return eligible[0]
        }
        return eligible[(index + 1) % eligible.count]
    }
}
