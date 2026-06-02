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
        let height: CGFloat

        var id: IndicatorKind { placeholder.kind }
    }

    struct Column {
        var items: [Item]
    }

    let columns: [Column]
    let spacing: CGFloat
    let outerPadding: CGFloat

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
        let scale = min(max(availableHeight / maxColumnHeight, 0.52), 1.0)
        let minimumHeight: CGFloat = 130

        let builtColumns = columns.map { column in
            Column(
                items: column.map { placeholder in
                    let scaledHeight = preferredTileHeight(for: placeholder.kind) * scale
                    return Item(
                        placeholder: placeholder,
                        height: max(minimumHeight, scaledHeight)
                    )
                }
            )
        }

        let score = (scale * 10_000) + tileWidth
        return LayoutCandidate(columns: builtColumns, score: score)
    }

    private static func fallbackCandidate(
        indicators: [IndicatorPlaceholder],
        availableHeight: CGFloat,
        spacing: CGFloat
    ) -> LayoutCandidate {
        let count = max(indicators.count, 1)
        let totalSpacing = spacing * CGFloat(max(count - 1, 0))
        let height = max((availableHeight - totalSpacing) / CGFloat(count), 130)
        let column = Column(
            items: indicators.map { Item(placeholder: $0, height: height) }
        )
        return LayoutCandidate(columns: [column], score: 0)
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
        case .wifi, .speaker, .bluetooth, .ringer:
            return 220
        }
    }
}
