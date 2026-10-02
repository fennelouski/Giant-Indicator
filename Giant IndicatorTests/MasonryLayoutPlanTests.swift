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
        IndicatorPlaceholder(kind: .chargingState, value: "On Battery"),
        IndicatorPlaceholder(kind: .volume, value: "30%"),
        IndicatorPlaceholder(kind: .playback, value: "Playing"),
        IndicatorPlaceholder(kind: .nowPlaying, value: "Track"),
        IndicatorPlaceholder(kind: .wifi, value: "Connected", subtitle: "Wi-Fi active"),
        IndicatorPlaceholder(kind: .speaker, value: "Speaker", subtitle: "Built-in"),
        IndicatorPlaceholder(kind: .bluetooth, value: "Off", subtitle: "Bluetooth disabled"),
        IndicatorPlaceholder(kind: .clock, value: "12:30 PM"),
        IndicatorPlaceholder(kind: .date, value: "Wednesday, June 3")
    ]

    private static let defaultFavoritePlaceholders: [IndicatorPlaceholder] = [
        IndicatorPlaceholder(kind: .battery, value: "50%"),
        IndicatorPlaceholder(kind: .chargingState, value: "On Battery"),
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
        #expect(indicatorItems(in: plan).count == Self.allIndicatorPlaceholders.count)
    }

    @Test func layoutFitsMacOSSmallWindow() async throws {
        let size = CGSize(width: 600, height: 520)
        let plan = MasonryLayoutPlan.build(indicators: Self.defaultFavoritePlaceholders, in: size)

        #expect(plan.allItemsHavePositiveSize)
        #expect(plan.fitsIn(size: size))
        #expect(plan.satisfiesReadableTileMetrics)
    }

    @Test func layoutPrefersWiderTilesOnMacOSLargeWindow() async throws {
        let narrowSize = CGSize(width: 393, height: 750)
        let wideSize = CGSize(width: 852, height: 393)

        let narrowPlan = MasonryLayoutPlan.build(
            indicators: Self.defaultFavoritePlaceholders,
            in: narrowSize
        )
        let widePlan = MasonryLayoutPlan.build(
            indicators: Self.defaultFavoritePlaceholders,
            in: wideSize
        )

        #expect(narrowPlan.fitsIn(size: narrowSize))
        #expect(widePlan.fitsIn(size: wideSize))
        #expect(maxTileWidth(in: widePlan) > maxTileWidth(in: narrowPlan))
    }

    @Test func progressiveKindLabelStrippingOrder() async throws {
        let states = TileKindLabelVisibility.progressiveStrippingStates
        #expect(states.count == TileKindLabelVisibility.strippingOrder.count + 1)
        #expect(states.first?.showsKindLabel(for: .volume) == true)
        #expect(states[1].showsKindLabel(for: .volume) == false)
        #expect(states[1].showsKindLabel(for: .chargingState) == true)
        #expect(states.last?.showsKindLabel(for: .chargingState) == false)
    }

    @Test func tightLayoutHidesMoreKindLabelsThanSpaciousLayout() async throws {
        let spacious = MasonryLayoutPlan.build(
            indicators: Self.allIndicatorPlaceholders,
            in: CGSize(width: 393, height: 852)
        )
        let tight = MasonryLayoutPlan.build(
            indicators: Self.allIndicatorPlaceholders,
            in: CGSize(width: 393, height: 480)
        )

        #expect(spacious.fitsIn(size: CGSize(width: 393, height: 852)))
        #expect(tight.fitsIn(size: CGSize(width: 393, height: 480)))
        #expect(tight.satisfiesReadableTileMetrics)

        let spaciousLabelCount = visibleKindLabelCount(in: spacious)
        let tightLabelCount = visibleKindLabelCount(in: tight)

        #expect(tightLabelCount <= spaciousLabelCount)
        if spaciousLabelCount > 0 {
            #expect(tightLabelCount < spaciousLabelCount)
        }

        let volumeItem = indicatorItems(in: tight).first { $0.placeholder.kind == .volume }
        #expect(volumeItem?.showsKindLabel == false)
    }

    @Test func spaciousLayoutShowsChargingStateKindLabel() async throws {
        let size = CGSize(width: 393, height: 852)
        let indicators = [
            IndicatorPlaceholder(kind: .battery, value: "50%"),
            IndicatorPlaceholder(kind: .chargingState, value: "Charging")
        ]
        let plan = MasonryLayoutPlan.build(indicators: indicators, in: size)

        let chargingItem = indicatorItems(in: plan).first { $0.placeholder.kind == .chargingState }

        #expect(chargingItem?.showsKindLabel == true)
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

    @Test func layoutDoesNotReserveSettingsChromeColumn() async throws {
        let size = CGSize(width: 393, height: 750)
        let plan = MasonryLayoutPlan.build(
            indicators: Self.defaultFavoritePlaceholders,
            in: size
        )

        #expect(!plan.layoutSignature.hasSuffix("-settings"))
        #expect(plan.columns.allSatisfy { !$0.items.isEmpty })
        #expect(plan.fitsIn(size: size))
    }

    @Test func singleIndicatorUsesContentSizedReadableHeight() async throws {
        let size = CGSize(width: 393, height: 852)
        for kind in [IndicatorKind.clock, .battery] {
            let plan = MasonryLayoutPlan.build(
                indicators: [IndicatorPlaceholder(kind: kind, value: "12:30 PM")],
                in: size
            )
            let items = indicatorItems(in: plan)
            #expect(items.count == 1)
            #expect(items[0].height >= 200)
            #expect(items[0].height <= 320)
            #expect(plan.fitsIn(size: size))
            #expect(plan.satisfiesReadableTileMetrics)
        }
    }

    @Test func twoIndicatorsAdaptBetweenPhoneStackAndWidePanel() async throws {
        let indicators = [
            IndicatorPlaceholder(kind: .clock, value: "12:30 PM"),
            IndicatorPlaceholder(kind: .date, value: "Wednesday, June 3")
        ]
        let phoneSize = CGSize(width: 393, height: 852)
        let phone = MasonryLayoutPlan.build(indicators: indicators, in: phoneSize)
        #expect(phone.columns.count == 1)
        #expect(indicatorItems(in: phone).count == 2)
        #expect(phone.fitsIn(size: phoneSize))
        #expect(phone.satisfiesReadableTileMetrics)
        let phoneHeights = indicatorItems(in: phone).map(\.height)
        #expect((phoneHeights.max() ?? 0) / (phoneHeights.min() ?? 1) <= 1.3)

        for size in [CGSize(width: 1024, height: 1366), CGSize(width: 1600, height: 1000)] {
            let plan = MasonryLayoutPlan.build(indicators: indicators, in: size)
            #expect(plan.columns.count == 2)
            #expect(plan.contentWidth <= 1040)
            #expect(indicatorItems(in: plan).allSatisfy { $0.height >= 280 && $0.height <= 360 })
            #expect(plan.fitsIn(size: size))
            #expect(plan.satisfiesReadableTileMetrics)
        }
    }

    @Test func sparseWideLayoutsUseAllColumnsWithoutStretching() async throws {
        let size = CGSize(width: 1600, height: 1000)
        let one = MasonryLayoutPlan.build(
            indicators: [IndicatorPlaceholder(kind: .clock, value: "12:30 PM")],
            in: size
        )
        #expect(one.contentWidth <= 720)
        #expect(indicatorItems(in: one).allSatisfy { $0.height >= 280 && $0.height <= 360 })

        let three = MasonryLayoutPlan.build(indicators: [
            IndicatorPlaceholder(kind: .clock, value: "12:30 PM"),
            IndicatorPlaceholder(kind: .date, value: "Wednesday, June 3"),
            IndicatorPlaceholder(kind: .volume, value: "30%")
        ], in: size)
        #expect(three.contentWidth <= 1120)
        #expect(three.columns.count >= 2)
        #expect(indicatorItems(in: three).count == 3)
        #expect(three.columns.allSatisfy { !$0.items.isEmpty })
        #expect(three.fitsIn(size: size))
        #expect(three.satisfiesReadableTileMetrics)

        let landscapeSize = CGSize(width: 852, height: 393)
        let paired = MasonryLayoutPlan.build(indicators: [
            IndicatorPlaceholder(kind: .battery, value: "50%"),
            IndicatorPlaceholder(kind: .chargingState, value: "Charging"),
            IndicatorPlaceholder(kind: .clock, value: "12:30 PM")
        ], in: landscapeSize)
        let batteryColumn = paired.columns.firstIndex { $0.items.contains { $0.id == .battery } }
        let chargingColumn = paired.columns.firstIndex { $0.items.contains { $0.id == .chargingState } }
        #expect(
            batteryColumn != nil && chargingColumn != nil && batteryColumn != chargingColumn,
            "Landscape columns: \(paired.columns.map { $0.items.map { "\($0.id):\($0.width)x\($0.height)" } })"
        )
        #expect(paired.columns.allSatisfy { !$0.items.isEmpty })
        #expect(indicatorItems(in: paired).count == 3)
        #expect(paired.fitsIn(size: landscapeSize))
        #expect(paired.satisfiesReadableTileMetrics)
    }

    private func indicatorItems(in plan: MasonryLayoutPlan) -> [MasonryLayoutPlan.Item] {
        plan.columns.flatMap(\.items)
    }

    private func visibleKindLabelCount(in plan: MasonryLayoutPlan) -> Int {
        indicatorItems(in: plan).filter { item in
            item.showsKindLabel && TileKindLabelVisibility.strippingOrder.contains(item.placeholder.kind)
        }.count
    }

    private func averageTileWidth(in plan: MasonryLayoutPlan) -> CGFloat {
        let items = indicatorItems(in: plan)
        guard !items.isEmpty else { return 0 }
        return items.map(\.width).reduce(0, +) / CGFloat(items.count)
    }

    private func maxTileWidth(in plan: MasonryLayoutPlan) -> CGFloat {
        indicatorItems(in: plan).map(\.width).max() ?? 0
    }

    private func averageTileHeight(in plan: MasonryLayoutPlan) -> CGFloat {
        let items = indicatorItems(in: plan)
        guard !items.isEmpty else { return 0 }
        return items.map(\.height).reduce(0, +) / CGFloat(items.count)
    }
}
