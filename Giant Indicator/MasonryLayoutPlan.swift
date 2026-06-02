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

        var id: IndicatorKind { placeholder.kind }
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

    static func build(indicators: [IndicatorPlaceholder], in size: CGSize) -> MasonryLayoutPlan {
        let outerPadding: CGFloat = 20
        let spacing: CGFloat = 16
        let availableWidth = max(size.width - (outerPadding * 2), 1)
        let availableHeight = max(size.height - (outerPadding * 2), 1)
        let maxColumnsByWidth = max(Int((availableWidth + spacing) / (160 + spacing)), 1)
        let maxColumns = min(maxColumnsByWidth, max(indicators.count, 1))

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

        let resolved = bestCandidate ?? fallbackCandidate(
            indicators: indicators,
            availableWidth: availableWidth,
            availableHeight: availableHeight,
            spacing: spacing
        )
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

        var builtColumns: [Column] = []
        var balancedHeights: [CGFloat] = []

        for column in columns {
            var heights = column.map { preferredTileHeight(for: $0.kind) * preferredScale }
            heights = heights.map { max($0, adaptiveMinimumHeight) }

            guard fitHeightsToColumn(
                &heights,
                availableHeight: availableHeight,
                spacing: spacing,
                minimumHeight: adaptiveMinimumHeight
            ) else {
                return nil
            }

            let items = zip(column, heights).map { placeholder, height in
                Item(placeholder: placeholder, width: tileWidth, height: height)
            }
            builtColumns.append(Column(items: items))
            balancedHeights.append(totalHeight(of: heights, spacing: spacing))
        }

        let readabilityScore = preferredScale * 10_000
        let widthScore = tileWidth * 10
        let balancePenalty = (balancedHeights.max() ?? 0) - (balancedHeights.min() ?? 0)
        let score = readabilityScore + widthScore - balancePenalty
        return LayoutCandidate(columns: builtColumns, score: score)
    }

    private static func fallbackCandidate(
        indicators: [IndicatorPlaceholder],
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        spacing: CGFloat
    ) -> LayoutCandidate {
        let count = max(indicators.count, 1)
        let totalSpacing = spacing * CGFloat(max(count - 1, 0))
        let perItemHeight = max((availableHeight - totalSpacing) / CGFloat(count), 1)
        let minimumHeight = adaptiveMinimumTileHeight(
            maxItemsInColumn: count,
            availableHeight: availableHeight,
            spacing: spacing
        )
        let height = max(perItemHeight, minimumHeight)
        let tileWidth = max(availableWidth, 1)
        let column = Column(
            items: indicators.map { Item(placeholder: $0, width: tileWidth, height: height) }
        )
        return LayoutCandidate(columns: [column], score: 0)
    }

    private static func fitHeightsToColumn(
        _ heights: inout [CGFloat],
        availableHeight: CGFloat,
        spacing: CGFloat,
        minimumHeight: CGFloat
    ) -> Bool {
        let currentTotal = totalHeight(of: heights, spacing: spacing)
        let overflow = currentTotal - availableHeight
        guard overflow > 0.5 else { return true }

        let shrinkable = heights.reduce(CGFloat(0)) { partial, value in
            partial + max(value - minimumHeight, 0)
        }
        guard shrinkable >= overflow else { return false }

        for index in heights.indices {
            let room = max(heights[index] - minimumHeight, 0)
            guard room > 0 else { continue }
            let reduction = overflow * (room / shrinkable)
            heights[index] = max(minimumHeight, heights[index] - reduction)
        }

        return totalHeight(of: heights, spacing: spacing) <= (availableHeight + 0.5)
    }

    private static func totalHeight(of heights: [CGFloat], spacing: CGFloat) -> CGFloat {
        guard !heights.isEmpty else { return 0 }
        let spacingTotal = spacing * CGFloat(max(heights.count - 1, 0))
        return heights.reduce(0, +) + spacingTotal
    }

    private static func adaptiveMinimumTileHeight(
        maxItemsInColumn: Int,
        availableHeight: CGFloat,
        spacing: CGFloat
    ) -> CGFloat {
        let itemCount = max(maxItemsInColumn, 1)
        let totalSpacing = spacing * CGFloat(max(itemCount - 1, 0))
        let perTileBudget = max((availableHeight - totalSpacing) / CGFloat(itemCount), 1)
        let readabilityLowerBound = max(44, perTileBudget * 0.55)
        return min(130, readabilityLowerBound, perTileBudget)
    }

    private static func preferredTileHeight(for kind: IndicatorKind) -> CGFloat {
        switch kind {
        case .weather:
            return 300
        case .battery:
            return 250
        case .volume:
            return 250
        case .playback:
            return 250
        case .nowPlaying:
            return 280
        case .wifi, .speaker, .bluetooth, .ringer:
            return 220
        }
    }
}
