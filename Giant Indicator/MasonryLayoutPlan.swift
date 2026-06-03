//
//  MasonryLayoutPlan.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct MasonryLayoutPlan {
    struct Item: Identifiable {
        let placeholder: IndicatorPlaceholder
        let width: CGFloat
        let height: CGFloat
        let showsKindLabel: Bool

        var id: IndicatorKind { placeholder.kind }

        init(
            placeholder: IndicatorPlaceholder,
            width: CGFloat,
            height: CGFloat,
            showsKindLabel: Bool
        ) {
            self.placeholder = placeholder
            self.width = width
            self.height = height
            self.showsKindLabel = showsKindLabel
        }
    }

    struct Column {
        var items: [Item]
    }

    let columns: [Column]
    let spacing: CGFloat
    let outerPadding: CGFloat

    var layoutSignature: String {
        let heightParts = columns.flatMap(\.items).map { Int($0.height.rounded()) }
        return "\(columns.count)-\(heightParts.map(String.init).joined(separator: ","))"
    }

    func fitsIn(size: CGSize) -> Bool {
        let availableHeight = max(size.height - (outerPadding * 2), 1)
        for column in columns {
            let heights = column.items.map(\.height)
            guard Self.totalHeight(of: heights, spacing: spacing) <= availableHeight + 0.5 else {
                return false
            }
        }
        return true
    }

    var allItemsHavePositiveSize: Bool {
        columns.flatMap(\.items).allSatisfy { $0.width > 0 && $0.height > 0 }
    }

    var satisfiesReadableTileMetrics: Bool {
        columns.flatMap(\.items).allSatisfy { item in
            let metrics = TileMetrics(width: item.width, height: item.height)
            return metrics.minimumContentHeight(
                for: item.placeholder.kind,
                showsKindLabel: item.showsKindLabel
            ) <= item.height + 0.5
        }
    }

    /// Maximum indicators that can fit at readable tile height without scrolling.
    static func maximumTileCount(for size: CGSize, spacing: CGFloat = 16, outerPadding: CGFloat = 20) -> Int {
        let availableHeight = max(size.height - (outerPadding * 2), 1)
        let tileHeight = TileMetrics.minimumReadableTileHeight
        return max(Int((availableHeight + spacing) / (tileHeight + spacing)), 1)
    }

    static func build(indicators: [IndicatorPlaceholder], in size: CGSize) -> MasonryLayoutPlan {
        let outerPadding: CGFloat = 20
        let spacing: CGFloat = 16
        let availableWidth = max(size.width - (outerPadding * 2), 1)
        let availableHeight = max(size.height - (outerPadding * 2), 1)
        let maxColumnsByWidth = max(Int((availableWidth + spacing) / (160 + spacing)), 1)
        var maxColumns = min(maxColumnsByWidth, max(indicators.count, 1))
        while maxColumns > 1 {
            let tileWidth = (availableWidth - (spacing * CGFloat(maxColumns - 1))) / CGFloat(maxColumns)
            if tileWidth >= 220 {
                break
            }
            maxColumns -= 1
        }

        var bestCandidate: LayoutCandidate?
        for columnCount in 1...maxColumns {
            guard let candidate = makeCandidate(
                indicators: indicators,
                columnCount: columnCount,
                availableWidth: availableWidth,
                availableHeight: availableHeight,
                spacing: spacing
            ) else {
                continue
            }

            if let currentBest = bestCandidate {
                if candidate.score > currentBest.score {
                    bestCandidate = candidate
                }
            } else {
                bestCandidate = candidate
            }
        }

        let resolved: LayoutCandidate
        if let bestCandidate {
            resolved = bestCandidate
        } else {
            var retried: LayoutCandidate?
            for columnCount in stride(from: maxColumns, through: 1, by: -1) {
                if let candidate = makeCandidate(
                    indicators: indicators,
                    columnCount: columnCount,
                    availableWidth: availableWidth,
                    availableHeight: availableHeight,
                    spacing: spacing
                ) {
                    retried = candidate
                    break
                }
            }
            resolved = retried ?? fallbackCandidate(
                indicators: indicators,
                availableWidth: availableWidth,
                availableHeight: availableHeight,
                spacing: spacing
            )
        }
        return MasonryLayoutPlan(columns: resolved.columns, spacing: spacing, outerPadding: outerPadding)
    }

    private struct LayoutCandidate {
        let columns: [Column]
        let score: CGFloat
    }

    private static func makeCandidate(
        indicators: [IndicatorPlaceholder],
        columnCount: Int,
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        spacing: CGFloat
    ) -> LayoutCandidate? {
        guard columnCount > 0 else { return nil }

        let tileWidth = (availableWidth - (spacing * CGFloat(columnCount - 1))) / CGFloat(columnCount)
        guard tileWidth >= 140 else { return nil }

        var columnHeights = Array(repeating: CGFloat(0), count: columnCount)
        var columns = Array(repeating: [IndicatorPlaceholder](), count: columnCount)

        for indicator in indicators {
            let target = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            let baseHeight = preferredTileHeight(for: indicator.kind)
            if !columns[target].isEmpty {
                columnHeights[target] += spacing
            }
            columnHeights[target] += baseHeight
            columns[target].append(indicator)
        }

        let maxColumnHeight = columnHeights.max() ?? 1
        let preferredScale = min(max(availableHeight / maxColumnHeight, 0), 1.0)
        let maxItemsInAnyColumn = columns.map(\.count).max() ?? 1
        let adaptiveMinimumHeight = adaptiveMinimumTileHeight(
            maxItemsInColumn: maxItemsInAnyColumn,
            availableHeight: availableHeight,
            spacing: spacing
        )

        for kindLabelVisibility in TileKindLabelVisibility.progressiveStrippingStates {
            var builtColumns: [Column] = []
            var balancedHeights: [CGFloat] = []
            var layoutFailed = false

            for column in columns {
                var heights = column.map { preferredTileHeight(for: $0.kind) * preferredScale }
                heights = heights.map { max($0, adaptiveMinimumHeight) }

                let contentFloors = zip(column, heights).map { placeholder, height in
                    stabilizedTileHeight(
                        width: tileWidth,
                        initial: height,
                        minimumHeight: adaptiveMinimumHeight,
                        kind: placeholder.kind,
                        kindLabelVisibility: kindLabelVisibility
                    )
                }
                heights = zip(heights, contentFloors).map { max($0, $1) }

                guard fitHeightsToColumn(
                    &heights,
                    contentFloors: contentFloors,
                    availableHeight: availableHeight,
                    spacing: spacing
                ) else {
                    layoutFailed = true
                    break
                }

                let items = zip(column, heights).map { placeholder, height in
                    return Item(
                        placeholder: placeholder,
                        width: tileWidth,
                        height: height,
                        showsKindLabel: kindLabelVisibility.showsKindLabel(for: placeholder.kind)
                    )
                }

                guard itemsSatisfyReadableTileMetrics(items) else {
                    layoutFailed = true
                    break
                }

                builtColumns.append(Column(items: items))
                balancedHeights.append(totalHeight(of: heights, spacing: spacing))
            }

            guard !layoutFailed else { continue }

            let readabilityScore = preferredScale * 10_000
            let widthScore = min(tileWidth, 360) * 10
            let balancePenalty = (balancedHeights.max() ?? 0) - (balancedHeights.min() ?? 0)
            let columnCountBonus = columnCount > 1 ? CGFloat(columnCount) * 50 : 0
            let multiColumnBonus: CGFloat = columnCount > 1 && tileWidth >= 200 ? 50_000 : 0
            let score = readabilityScore + widthScore - balancePenalty + columnCountBonus
                + multiColumnBonus + kindLabelVisibility.kindLabelScoreBonus
            return LayoutCandidate(columns: builtColumns, score: score)
        }

        return nil
    }

    private static func fallbackCandidate(
        indicators: [IndicatorPlaceholder],
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        spacing: CGFloat
    ) -> LayoutCandidate {
        let maxColumnsByWidth = max(Int((availableWidth + spacing) / (140 + spacing)), 1)
        let maxColumns = min(maxColumnsByWidth, max(indicators.count, 1))

        for columnCount in stride(from: maxColumns, through: 1, by: -1) {
            if let candidate = makeCandidate(
                indicators: indicators,
                columnCount: columnCount,
                availableWidth: availableWidth,
                availableHeight: availableHeight,
                spacing: spacing
            ) {
                return candidate
            }
        }

        let count = max(indicators.count, 1)
        let totalSpacing = spacing * CGFloat(max(count - 1, 0))
        let perItemHeight = max((availableHeight - totalSpacing) / CGFloat(count), 1)
        let tileWidth = max(availableWidth, 1)

        for kindLabelVisibility in TileKindLabelVisibility.progressiveStrippingStates {
            let heights = indicators.map { placeholder in
                stabilizedTileHeight(
                    width: tileWidth,
                    initial: perItemHeight,
                    minimumHeight: perItemHeight,
                    kind: placeholder.kind,
                    kindLabelVisibility: kindLabelVisibility
                )
            }

            guard totalHeight(of: heights, spacing: spacing) <= availableHeight + 0.5 else {
                continue
            }

            let items = zip(indicators, heights).map { placeholder, height in
                Item(
                    placeholder: placeholder,
                    width: tileWidth,
                    height: height,
                    showsKindLabel: kindLabelVisibility.showsKindLabel(for: placeholder.kind)
                )
            }

            guard itemsSatisfyReadableTileMetrics(items) else { continue }

            return LayoutCandidate(
                columns: [Column(items: items)],
                score: kindLabelVisibility.kindLabelScoreBonus
            )
        }

        let kindLabelVisibility = TileKindLabelVisibility.hidingBatteryAndVolume
        let heights = indicators.map { placeholder in
            stabilizedTileHeight(
                width: tileWidth,
                initial: perItemHeight,
                minimumHeight: perItemHeight,
                kind: placeholder.kind,
                kindLabelVisibility: kindLabelVisibility
            )
        }
        let column = Column(
            items: zip(indicators, heights).map { placeholder, height in
                Item(
                    placeholder: placeholder,
                    width: tileWidth,
                    height: height,
                    showsKindLabel: false
                )
            }
        )
        return LayoutCandidate(columns: [column], score: 0)
    }

    private static func itemsSatisfyReadableTileMetrics(_ items: [Item]) -> Bool {
        items.allSatisfy { item in
            let metrics = TileMetrics(width: item.width, height: item.height)
            return metrics.minimumContentHeight(
                for: item.placeholder.kind,
                showsKindLabel: item.showsKindLabel
            ) <= item.height + 0.5
        }
    }

    private static func stabilizedTileHeight(
        width: CGFloat,
        initial: CGFloat,
        minimumHeight: CGFloat,
        kind: IndicatorKind,
        kindLabelVisibility: TileKindLabelVisibility
    ) -> CGFloat {
        var target = initial
        for _ in 0..<4 {
            let metrics = TileMetrics(width: width, height: target)
            let required = metrics.minimumContentHeight(
                for: kind,
                kindLabelVisibility: kindLabelVisibility
            )
            if required <= target + 0.5 {
                break
            }
            target = required
        }
        return max(minimumHeight, target)
    }

    private static func fitHeightsToColumn(
        _ heights: inout [CGFloat],
        contentFloors: [CGFloat],
        availableHeight: CGFloat,
        spacing: CGFloat
    ) -> Bool {
        let currentTotal = totalHeight(of: heights, spacing: spacing)
        let overflow = currentTotal - availableHeight
        guard overflow > 0.5 else { return true }

        let shrinkable = zip(heights, contentFloors).reduce(CGFloat(0)) { partial, pair in
            partial + max(pair.0 - pair.1, 0)
        }
        guard shrinkable >= overflow else { return false }

        for index in heights.indices {
            let floor = contentFloors[index]
            let room = max(heights[index] - floor, 0)
            guard room > 0 else { continue }
            let reduction = overflow * (room / shrinkable)
            heights[index] = max(floor, heights[index] - reduction)
        }

        return totalHeight(of: heights, spacing: spacing) <= (availableHeight + 0.5)
    }

    private static func totalHeight(of heights: [CGFloat], spacing: CGFloat) -> CGFloat {
        guard !heights.isEmpty else { return 0 }
        let spacingTotal = spacing * CGFloat(max(heights.count - 1, 0))
        return heights.reduce(0, +) + spacingTotal
    }

    private static func perTileHeightBudget(
        maxItemsInColumn: Int,
        availableHeight: CGFloat,
        spacing: CGFloat
    ) -> CGFloat {
        let itemCount = max(maxItemsInColumn, 1)
        let totalSpacing = spacing * CGFloat(max(itemCount - 1, 0))
        return max((availableHeight - totalSpacing) / CGFloat(itemCount), 1)
    }

    private static func adaptiveMinimumTileHeight(
        maxItemsInColumn: Int,
        availableHeight: CGFloat,
        spacing: CGFloat
    ) -> CGFloat {
        let perTileBudget = perTileHeightBudget(
            maxItemsInColumn: maxItemsInColumn,
            availableHeight: availableHeight,
            spacing: spacing
        )
        return min(TileMetrics.minimumReadableTileHeight, perTileBudget)
    }

    private static func preferredTileHeight(for kind: IndicatorKind) -> CGFloat {
        switch kind {
        case .weather:
            return 300
        case .battery:
            return 250
        case .chargingState:
            return 220
        case .volume:
            return 250
        case .playback:
            return 250
        case .nowPlaying:
            return 280
        case .wifi, .speaker, .bluetooth, .ringer:
            return 220
        case .clock:
            return 240
        case .date:
            return 260
        }
    }
}
