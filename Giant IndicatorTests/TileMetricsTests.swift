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

    @Test func metricsRespectMinimumReadableSizes() async throws {
        let metrics = TileMetrics(width: 120, height: 90)

        #expect(metrics.symbolFontSize >= 40)
        #expect(metrics.valueFontSize >= 34)
        #expect(metrics.titleFontSize >= 18)
        #expect(metrics.subtitleFontSize >= 15)
        #expect(metrics.iconHeight >= 44)
        #expect(metrics.padding >= 16)
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
}
