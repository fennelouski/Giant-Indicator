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
        columns.flatMap(\.items).allSatisfy(Self.itemSatisfiesReadableTileMetrics)
    }

    /// Maximum indicators that can fit at readable tile height without scrolling.
    static func maximumTileCount(for size: CGSize, spacing: CGFloat = 16, outerPadding: CGFloat = 20) -> Int {
        let availableHeight = max(size.height - (outerPadding * 2), 1)
        let tileHeight = TileMetrics.minimumReadableTileHeight
        return max(Int((availableHeight + spacing) / (tileHeight + spacing)), 1)
    }

    static func build(
        indicators: [IndicatorPlaceholder],
        in size: CGSize
    ) -> MasonryLayoutPlan {
        let outerPadding: CGFloat = 20
        let spacing: CGFloat = 16
        let availableWidth = max(size.width - (outerPadding * 2), 1)
        let availableHeight = max(size.height - (outerPadding * 2), 1)
        let indicatorAvailableWidth = availableWidth
        let isLandscape = availableWidth > availableHeight

        let maxColumnsByWidth = max(
            Int((indicatorAvailableWidth + spacing) / (160 + spacing)),
            1
        )
        var maxColumns = min(maxColumnsByWidth, max(indicators.count, 1))
        while maxColumns > 1 {
            let tileWidth = (indicatorAvailableWidth - (spacing * CGFloat(maxColumns - 1))) / CGFloat(maxColumns)
            if tileWidth >= 220 {
                break
            }
            maxColumns -= 1
        }

        let prefersSideBySideBatteryAndCharging = isLandscape
            && indicators.count >= 2
            && indicators[0].kind == .battery
            && indicators[1].kind == .chargingState

        let columnCountsToEvaluate: [Int] = {
            if prefersSideBySideBatteryAndCharging, maxColumns >= 2 {
                return Array(2...maxColumns)
            }
            return Array(1...maxColumns)
        }()

        var bestCandidate: LayoutCandidate?
        for columnCount in columnCountsToEvaluate {
            guard let candidate = makeCandidate(
                indicators: indicators,
                columnCount: columnCount,
                availableWidth: indicatorAvailableWidth,
                availableHeight: availableHeight,
                spacing: spacing,
                isLandscape: isLandscape
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

        var resolved: LayoutCandidate
        if let bestCandidate {
            resolved = bestCandidate
        } else {
            var retried: LayoutCandidate?
            for columnCount in stride(from: maxColumns, through: 1, by: -1) {
                if let candidate = makeCandidate(
                    indicators: indicators,
                    columnCount: columnCount,
                    availableWidth: indicatorAvailableWidth,
                    availableHeight: availableHeight,
                    spacing: spacing,
                    isLandscape: isLandscape
                ) {
                    retried = candidate
                    break
                }
            }
            resolved = retried ?? fallbackCandidate(
                indicators: indicators,
                availableWidth: indicatorAvailableWidth,
                availableHeight: availableHeight,
                spacing: spacing,
                isLandscape: isLandscape
            )
        }

        if let manualLandscape = manualTwoColumnBatteryChargingLandscapeLayout(
            indicators: indicators,
            availableWidth: indicatorAvailableWidth,
            availableHeight: availableHeight,
            spacing: spacing,
            isLandscape: isLandscape
        ),
            indicators.count <= 3,
            batteryAndChargingShareColumn(in: resolved.columns) || resolved.columns.count == 1
        {
            resolved = manualLandscape
        } else if let forcedLandscape = forcedLandscapeBatteryChargingClockCandidate(
            indicators: indicators,
            availableWidth: indicatorAvailableWidth,
            availableHeight: availableHeight,
            spacing: spacing,
            isLandscape: isLandscape
        ) {
            resolved = forcedLandscape
        } else if let pairedLandscape = preferredBatteryChargingLandscapeCandidate(
            indicators: indicators,
            current: resolved,
            maxColumns: maxColumns,
            availableWidth: indicatorAvailableWidth,
            availableHeight: availableHeight,
            spacing: spacing,
            isLandscape: isLandscape
        ) {
            resolved = pairedLandscape
        }

        return MasonryLayoutPlan(columns: resolved.columns, spacing: spacing, outerPadding: outerPadding)
    }

    private struct LayoutCandidate {
        let columns: [Column]
        let score: CGFloat
    }

    private static func manualTwoColumnBatteryChargingLandscapeLayout(
        indicators: [IndicatorPlaceholder],
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        spacing: CGFloat,
        isLandscape: Bool
    ) -> LayoutCandidate? {
        guard isLandscape,
              indicators.count >= 2,
              indicators[0].kind == .battery,
              indicators[1].kind == .chargingState
        else {
            return nil
        }

        let tileWidth = (availableWidth - spacing) / 2
        guard tileWidth >= 140 else { return nil }

        let leftPlaceholders = [indicators[0]]
        let rightPlaceholders = Array(indicators.dropFirst())
        let rightBudget = perTileHeightBudget(
            maxItemsInColumn: rightPlaceholders.count,
            availableHeight: availableHeight,
            spacing: spacing
        )

        let leftItem = Item(
            placeholder: indicators[0],
            width: tileWidth,
            height: availableHeight,
            showsKindLabel: false
        )

        var rightHeights = rightPlaceholders.map { _ in rightBudget }
        if totalHeight(of: rightHeights, spacing: spacing) > availableHeight + 0.5 {
            let overflow = totalHeight(of: rightHeights, spacing: spacing) - availableHeight
            let shrinkable = rightHeights.reduce(0) { $0 + max($1 - TileMetrics.minimumReadableTileHeight, 0) }
            if shrinkable >= overflow {
                for index in rightHeights.indices {
                    let floor = TileMetrics.minimumReadableTileHeight
                    let room = max(rightHeights[index] - floor, 0)
                    guard room > 0, shrinkable > 0 else { continue }
                    rightHeights[index] = max(floor, rightHeights[index] - overflow * (room / shrinkable))
                }
            }
        }

        let rightItems = zip(rightPlaceholders, rightHeights).map { placeholder, height in
            Item(
                placeholder: placeholder,
                width: tileWidth,
                height: height,
                showsKindLabel: false
            )
        }

        return LayoutCandidate(
            columns: [
                Column(items: [leftItem]),
                Column(items: rightItems)
            ],
            score: 0
        )
    }

    private static func forcedLandscapeBatteryChargingClockCandidate(
        indicators: [IndicatorPlaceholder],
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        spacing: CGFloat,
        isLandscape: Bool
    ) -> LayoutCandidate? {
        guard isLandscape,
              indicators.count == 3,
              indicators[0].kind == .battery,
              indicators[1].kind == .chargingState,
              indicators[2].kind == .clock
        else {
            return nil
        }

        for columnCount in [2, 3] {
            guard let candidate = makeCandidate(
                indicators: indicators,
                columnCount: columnCount,
                availableWidth: availableWidth,
                availableHeight: availableHeight,
                spacing: spacing,
                isLandscape: isLandscape
            ),
                !batteryAndChargingShareColumn(in: candidate.columns)
            else {
                continue
            }
            return candidate
        }

        return nil
    }

    private static func preferredBatteryChargingLandscapeCandidate(
        indicators: [IndicatorPlaceholder],
        current: LayoutCandidate,
        maxColumns: Int,
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        spacing: CGFloat,
        isLandscape: Bool
    ) -> LayoutCandidate? {
        guard isLandscape,
              indicators.count >= 2,
              indicators[0].kind == .battery,
              indicators[1].kind == .chargingState,
              batteryAndChargingShareColumn(in: current.columns)
        else {
            return nil
        }

        for columnCount in stride(from: min(maxColumns, indicators.count), through: 2, by: -1) {
            guard let candidate = makeCandidate(
                indicators: indicators,
                columnCount: columnCount,
                availableWidth: availableWidth,
                availableHeight: availableHeight,
                spacing: spacing,
                isLandscape: isLandscape
            ),
                !batteryAndChargingShareColumn(in: candidate.columns)
            else {
                continue
            }
            return candidate
        }

        return nil
    }

    private static func batteryAndChargingShareColumn(in columns: [Column]) -> Bool {
        let batteryColumn = columnIndex(for: .battery, in: columns)
        let chargingColumn = columnIndex(for: .chargingState, in: columns)
        guard let batteryColumn, let chargingColumn else { return false }
        return batteryColumn == chargingColumn
    }

    private static func columnIndex(for kind: IndicatorKind, in columns: [Column]) -> Int? {
        columns.enumerated().first { _, column in
            column.items.contains { $0.placeholder.kind == kind }
        }?.offset
    }

    private static func distributeIndicators(
        _ indicators: [IndicatorPlaceholder],
        columnCount: Int,
        spacing: CGFloat,
        isLandscape: Bool
    ) -> [[IndicatorPlaceholder]] {
        var columns = Array(repeating: [IndicatorPlaceholder](), count: columnCount)

        if isLandscape {
            if columnCount >= 2,
               indicators.count >= 2,
               indicators[0].kind == .battery,
               indicators[1].kind == .chargingState
            {
                columns[0].append(indicators[0])
                columns[1].append(indicators[1])
                for indicator in indicators.dropFirst(2) {
                    columns[0].append(indicator)
                }
                return columns
            }

            for (index, indicator) in indicators.enumerated() {
                columns[index % columnCount].append(indicator)
            }
            return columns
        }

        distributeRemainingIndicators(indicators, into: &columns, spacing: spacing)
        return columns
    }

    private static func distributeRemainingIndicators(
        _ indicators: [IndicatorPlaceholder],
        into columns: inout [[IndicatorPlaceholder]],
        spacing: CGFloat
    ) {
        guard !columns.isEmpty else { return }

        var columnHeights = columns.map { column in
            column.enumerated().reduce(CGFloat(0)) { partial, pair in
                let height = preferredTileHeight(for: pair.element.kind)
                let spacingBefore = pair.offset > 0 ? spacing : 0
                return partial + spacingBefore + height
            }
        }

        for indicator in indicators {
            let target = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            let baseHeight = preferredTileHeight(for: indicator.kind)
            if !columns[target].isEmpty {
                columnHeights[target] += spacing
            }
            columnHeights[target] += baseHeight
            columns[target].append(indicator)
        }
    }

    private static func makeCandidate(
        indicators: [IndicatorPlaceholder],
        columnCount: Int,
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        spacing: CGFloat,
        isLandscape: Bool
    ) -> LayoutCandidate? {
        guard columnCount > 0 else { return nil }

        let tileWidth = (availableWidth - (spacing * CGFloat(columnCount - 1))) / CGFloat(columnCount)
        guard tileWidth >= 140 else { return nil }

        let indicatorColumns = distributeIndicators(
            indicators,
            columnCount: columnCount,
            spacing: spacing,
            isLandscape: isLandscape
        )

        var columnHeights = indicatorColumns.map { column in
            column.enumerated().reduce(CGFloat(0)) { partial, pair in
                let height = preferredTileHeight(for: pair.element.kind)
                let spacingBefore = pair.offset > 0 ? spacing : 0
                return partial + spacingBefore + height
            }
        }
        let maxColumnHeight = columnHeights.max() ?? 1
        let preferredScale: CGFloat = {
            if indicators.count == 1 {
                return availableHeight / maxColumnHeight
            }
            return min(max(availableHeight / maxColumnHeight, 0), 1.0)
        }()
        let maxItemsInAnyColumn = indicatorColumns.map(\.count).max() ?? 1
        let adaptiveMinimumHeight = adaptiveMinimumTileHeight(
            maxItemsInColumn: maxItemsInAnyColumn,
            availableHeight: availableHeight,
            spacing: spacing
        )

        for kindLabelVisibility in TileKindLabelVisibility.progressiveStrippingStates {
            var builtColumns: [Column] = []
            var balancedHeights: [CGFloat] = []
            var layoutFailed = false

            for column in indicatorColumns {
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
                    Item(
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
            let landscapeFullRowBonus: CGFloat = {
                guard isLandscape, columnCount > 1 else { return 0 }
                let targetColumns = min(indicators.count, columnCount)
                return columnCount >= targetColumns ? 5_000 : 0
            }()
            let landscapeSingleColumnPenalty: CGFloat =
                isLandscape && columnCount == 1 && indicators.count >= 2 ? -100_000 : 0
            let score = readabilityScore + widthScore - balancePenalty + columnCountBonus
                + multiColumnBonus + landscapeFullRowBonus + landscapeSingleColumnPenalty
                + kindLabelVisibility.kindLabelScoreBonus
            return LayoutCandidate(columns: builtColumns, score: score)
        }

        return nil
    }

    private static func fallbackCandidate(
        indicators: [IndicatorPlaceholder],
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        spacing: CGFloat,
        isLandscape: Bool
    ) -> LayoutCandidate {
        let maxColumnsByWidth = max(Int((availableWidth + spacing) / (140 + spacing)), 1)
        let maxColumns = min(maxColumnsByWidth, max(indicators.count, 1))

        for columnCount in stride(from: maxColumns, through: 1, by: -1) {
            if let candidate = makeCandidate(
                indicators: indicators,
                columnCount: columnCount,
                availableWidth: availableWidth,
                availableHeight: availableHeight,
                spacing: spacing,
                isLandscape: isLandscape
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
        let items = zip(indicators, heights).map { placeholder, height in
            Item(
                placeholder: placeholder,
                width: tileWidth,
                height: height,
                showsKindLabel: false
            )
        }
        return LayoutCandidate(columns: [Column(items: items)], score: 0)
    }

    private static func itemsSatisfyReadableTileMetrics(_ items: [Item]) -> Bool {
        items.allSatisfy(itemSatisfiesReadableTileMetrics)
    }

    private static func itemSatisfiesReadableTileMetrics(_ item: Item) -> Bool {
        let metrics = TileMetrics(width: item.width, height: item.height)
        guard metrics.minimumContentHeight(
            for: item.placeholder.kind,
            showsKindLabel: item.showsKindLabel
        ) <= item.height + 0.5 else {
            return false
        }

        if item.placeholder.kind == .clock {
            return metrics.clockTimeFitsAtReadableScale()
        }

        return true
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
        case .wifi, .speaker, .bluetooth:
            return 220
        case .clock:
            return 240
        case .date:
            return 260
        }
    }
}
