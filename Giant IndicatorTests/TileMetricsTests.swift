//
//  TileMetricsTests.swift
//  Giant IndicatorTests
//
//  Created by Nathan Fennel on 6/2/26.
//

import CoreGraphics
import Testing
@testable import Giant_Indicator

struct TileMetricsTests {

    @Test func metricsNeverExceedAssignedTileHeight() async throws {
        let metrics = TileMetrics(width: 120, height: 50)

        #expect(metrics.minimumContentHeight <= metrics.height + 2)
        #expect(metrics.iconHeight <= metrics.height * 0.5)
        #expect(metrics.valueFontSize <= metrics.height * 0.4)
        #expect(metrics.minimumContentHeight <= metrics.height + 2)
    }

    @Test func metricsScaleUpOnLargeTiles() async throws {
        let compact = TileMetrics(width: 180, height: 140)
        let large = TileMetrics(width: 520, height: 360)

        #expect(large.symbolFontSize > compact.symbolFontSize)
        #expect(large.valueFontSize > compact.valueFontSize)
        #expect(large.titleFontSize > compact.titleFontSize)
        #expect(large.subtitleFontSize > compact.subtitleFontSize)
        #expect(large.iconHeight > compact.iconHeight)
        #expect(large.padding > compact.padding)
    }

    @Test func minimumReadableTileHeightIsStable() async throws {
        #expect(TileMetrics.minimumReadableTileHeight == 130)
    }

    @Test func volumeKindLabelIncreasesMinimumContentHeight() async throws {
        let metrics = TileMetrics(width: 200, height: 180)
        let withLabel = metrics.minimumContentHeight(for: .volume, showsKindLabel: true)
        let withoutLabel = metrics.minimumContentHeight(for: .volume, showsKindLabel: false)

        #expect(withLabel > withoutLabel)
    }

    @Test func narrowClockTileFailsReadableScaleCheck() async throws {
        let metrics = TileMetrics(width: 80, height: 200)
        #expect(!metrics.clockTimeFitsAtReadableScale())
    }

    @Test func wideClockTilePassesReadableScaleCheck() async throws {
        let metrics = TileMetrics(width: 320, height: 200)
        #expect(metrics.clockTimeFitsAtReadableScale())
    }

    @Test func chargingStateKindLabelIncreasesMinimumContentHeight() async throws {
        let metrics = TileMetrics(width: 200, height: 180)
        let withLabel = metrics.minimumContentHeight(for: .chargingState, showsKindLabel: true)
        let withoutLabel = metrics.minimumContentHeight(for: .chargingState, showsKindLabel: false)

        #expect(withLabel > withoutLabel)
    }
}
