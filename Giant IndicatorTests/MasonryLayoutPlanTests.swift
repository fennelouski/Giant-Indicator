//
//  MasonryLayoutPlanTests.swift
//  Giant IndicatorTests
//
//  Created by Nathan Fennel on 6/2/26.
//

import CoreGraphics
import Testing
@testable import Giant_Indicator

@Suite(.serialized)
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
        IndicatorPlaceholder(kind: .ringer, value: "Silent", subtitle: "Muted alerts"),
        IndicatorPlaceholder(kind: .clock, value: "12:30 PM"),
        IndicatorPlaceholder(kind: .date, value: "Wednesday, June 3")
    ]

    private static let defaultFavoritePlaceholders: [IndicatorPlaceholder] = [
        IndicatorPlaceholder(kind: .battery, value: "50%"),
        IndicatorPlaceholder(kind: .volume, value: "30%"),
        IndicatorPlaceholder(kind: .wifi, value: "Connected", subtitle: "Wi-Fi active"),
        IndicatorPlaceholder(kind: .clock, value: "12:30 PM"),
        IndicatorPlaceholder(kind: .date, value: "Wednesday, June 3"),
        IndicatorPlaceholder(kind: .weather, value: "72°", subtitle: "Sunny")
    ]

    @Test func layoutFitsIPhonePortraitWithDefaultFavorites() async throws {
        let size = CGSize(width: 393, height: 750)
        let plan = MasonryLayoutPlan.build(indicators: Self.defaultFavoritePlaceholders, in: size)

        #expect(plan.allItemsHavePositiveSize)
        #expect(plan.fitsIn(size: size))
        #expect(plan.satisfiesReadableTileMetrics)
    }

    @Test func layoutFitsIPhonePortraitWithAllIndicatorsReadable() async throws {
        let size = CGSize(width: 393, height: 852)
        let plan = MasonryLayoutPlan.build(indicators: Self.allIndicatorPlaceholders, in: size)

        #expect(plan.allItemsHavePositiveSize)
        #expect(plan.fitsIn(size: size))
        #expect(plan.satisfiesReadableTileMetrics)
    }

    @Test func maximumTileCountUsesReadableTileHeight() async throws {
        let size = CGSize(width: 393, height: 750)
        let maxCount = MasonryLayoutPlan.maximumTileCount(for: size)

        #expect(maxCount >= 4)
        #expect(maxCount < Self.allIndicatorPlaceholders.count)
    }

    @Test func layoutFitsIPadOneThirdSplitPortrait() async throws {
        let size = CGSize(width: 320, height: 1024)
        let plan = MasonryLayoutPlan.build(indicators: Self.allIndicatorPlaceholders, in: size)

        #expect(plan.allItemsHavePositiveSize)
        #expect(plan.fitsIn(size: size))
        #expect(plan.satisfiesReadableTileMetrics)
        #expect(plan.columns.flatMap(\.items).count == Self.allIndicatorPlaceholders.count)
    }

    @Test func layoutFitsMacOSSmallWindow() async throws {
        let size = CGSize(width: 600, height: 520)
        let plan = MasonryLayoutPlan.build(indicators: Self.defaultFavoritePlaceholders, in: size)

        #expect(plan.allItemsHavePositiveSize)
        #expect(plan.fitsIn(size: size))
        #expect(plan.satisfiesReadableTileMetrics)
    }

    @Test func layoutPrefersWiderTilesOnMacOSLargeWindow() async throws {
        let canvasHeight: CGFloat = 900
        let narrowSize = CGSize(width: 420, height: canvasHeight)
        let wideSize = CGSize(width: 900, height: canvasHeight)

        let narrowPlan = MasonryLayoutPlan.build(indicators: Self.defaultFavoritePlaceholders, in: narrowSize)
        let widePlan = MasonryLayoutPlan.build(indicators: Self.defaultFavoritePlaceholders, in: wideSize)

        #expect(narrowPlan.fitsIn(size: narrowSize))
        #expect(widePlan.fitsIn(size: wideSize))
        #expect(maxTileWidth(in: widePlan) > maxTileWidth(in: narrowPlan))
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

    private func maxTileWidth(in plan: MasonryLayoutPlan) -> CGFloat {
        plan.columns.flatMap(\.items).map(\.width).max() ?? 0
    }

    private func averageTileHeight(in plan: MasonryLayoutPlan) -> CGFloat {
        let items = plan.columns.flatMap(\.items)
        guard !items.isEmpty else { return 0 }
        return items.map(\.height).reduce(0, +) / CGFloat(items.count)
    }
}
