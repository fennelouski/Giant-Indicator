//
//  MasonryLayoutPlanTests.swift
//  Giant IndicatorTests
//
//  Created by Nathan Fennel on 6/2/26.
//

import CoreGraphics
import Testing
@testable import Giant_Indicator

@MainActor
struct MasonryLayoutPlanTests {

    private static let allIndicatorPlaceholders: [IndicatorPlaceholder] = [
        IndicatorPlaceholder(kind: .weather, value: "72°", subtitle: "Sunny"),
        IndicatorPlaceholder(kind: .battery, value: "50%"),
        IndicatorPlaceholder(kind: .volume, value: "30%"),
        IndicatorPlaceholder(kind: .playback, value: "Playing"),
        IndicatorPlaceholder(kind: .nowPlaying, value: "Track"),
        IndicatorPlaceholder(kind: .wifi, value: "Connected", subtitle: "Wi-Fi active"),
        IndicatorPlaceholder(kind: .speaker, value: "Speaker", subtitle: "Built-in"),
        IndicatorPlaceholder(kind: .bluetooth, value: "Off", subtitle: "Bluetooth disabled"),
        IndicatorPlaceholder(kind: .ringer, value: "Silent", subtitle: "Muted alerts")
    ]

    @Test func layoutFitsIPadOneThirdSplitPortrait() async throws {
        let size = CGSize(width: 320, height: 1024)
        let plan = MasonryLayoutPlan.build(indicators: Self.allIndicatorPlaceholders, in: size)

        #expect(plan.allItemsHavePositiveSize)
        #expect(plan.fitsIn(size: size))
        #expect(plan.columns.flatMap(\.items).count == Self.allIndicatorPlaceholders.count)
    }

    @Test func layoutAdaptsTileWidthAcrossIPadSizes() async throws {
        let splitThird = CGSize(width: 320, height: 1024)
        let fullLandscape = CGSize(width: 1194, height: 834)

        let splitPlan = MasonryLayoutPlan.build(indicators: Self.allIndicatorPlaceholders, in: splitThird)
        let fullPlan = MasonryLayoutPlan.build(indicators: Self.allIndicatorPlaceholders, in: fullLandscape)

        #expect(splitPlan.allItemsHavePositiveSize)
        #expect(fullPlan.allItemsHavePositiveSize)
        #expect(splitPlan.fitsIn(size: splitThird))
        #expect(fullPlan.fitsIn(size: fullLandscape))

        let splitAverageWidth = averageTileWidth(in: splitPlan)
        let fullAverageWidth = averageTileWidth(in: fullPlan)
        #expect(fullAverageWidth > splitAverageWidth)

        let fullMinTileWidth = fullPlan.columns.flatMap(\.items).map(\.width).min() ?? 0
        #expect(fullMinTileWidth >= 140)
    }

    @Test func layoutFitsMacOSSmallWindow() async throws {
        let size = CGSize(width: 600, height: 400)
        let plan = MasonryLayoutPlan.build(indicators: Self.allIndicatorPlaceholders, in: size)

        #expect(plan.allItemsHavePositiveSize)
        #expect(plan.fitsIn(size: size))
    }

    @Test func layoutPrefersWiderTilesOnMacOSLargeWindow() async throws {
        let smallSize = CGSize(width: 600, height: 400)
        let largeSize = CGSize(width: 1200, height: 800)

        let smallPlan = MasonryLayoutPlan.build(indicators: Self.allIndicatorPlaceholders, in: smallSize)
        let largePlan = MasonryLayoutPlan.build(indicators: Self.allIndicatorPlaceholders, in: largeSize)

        let smallAverageWidth = averageTileWidth(in: smallPlan)
        let largeAverageWidth = averageTileWidth(in: largePlan)
        #expect(largeAverageWidth > smallAverageWidth)

        let smallAverageHeight = averageTileHeight(in: smallPlan)
        let largeAverageHeight = averageTileHeight(in: largePlan)
        #expect(largeAverageHeight >= smallAverageHeight)
    }

    @Test func layoutSignatureChangesWhenColumnCountChanges() async throws {
        let narrow = MasonryLayoutPlan.build(
            indicators: Self.allIndicatorPlaceholders,
            in: CGSize(width: 320, height: 1024)
        )
        let wide = MasonryLayoutPlan.build(
            indicators: Self.allIndicatorPlaceholders,
            in: CGSize(width: 1200, height: 800)
        )

        #expect(narrow.layoutSignature != wide.layoutSignature)
    }

    private func averageTileWidth(in plan: MasonryLayoutPlan) -> CGFloat {
        let items = plan.columns.flatMap(\.items)
        guard !items.isEmpty else { return 0 }
        return items.map(\.width).reduce(0, +) / CGFloat(items.count)
    }

    private func averageTileHeight(in plan: MasonryLayoutPlan) -> CGFloat {
        let items = plan.columns.flatMap(\.items)
        guard !items.isEmpty else { return 0 }
        return items.map(\.height).reduce(0, +) / CGFloat(items.count)
    }
}
