//
//  LandscapeMasonryLayoutPlanXCTests.swift
//  Giant IndicatorTests
//

import CoreGraphics
import XCTest
@testable import Giant_Indicator

final class LandscapeMasonryLayoutPlanXCTests: XCTestCase {

    @MainActor
    func testBatteryAndChargingInSeparateColumnsInLandscape() throws {
        let indicators = [
            IndicatorPlaceholder(kind: .battery, value: "50%"),
            IndicatorPlaceholder(kind: .chargingState, value: "Charging"),
            IndicatorPlaceholder(kind: .clock, value: "12:30 PM")
        ]
        let size = CGSize(width: 852, height: 393)
        let plan = MasonryLayoutPlan.build(indicators: indicators, in: size)

        let indicatorColumns = plan.columns
        let batteryColumn = Self.columnIndex(for: .battery, in: plan)
        let chargingColumn = Self.columnIndex(for: .chargingState, in: plan)

        XCTAssertGreaterThanOrEqual(indicatorColumns.count, 2)
        XCTAssertNotNil(batteryColumn)
        XCTAssertNotNil(chargingColumn)
        XCTAssertNotEqual(batteryColumn, chargingColumn)
        XCTAssertTrue(plan.fitsIn(size: size))
    }

    @MainActor
    private static func columnIndex(for kind: IndicatorKind, in plan: MasonryLayoutPlan) -> Int? {
        plan.columns.enumerated().first { _, column in
            column.items.contains { $0.placeholder.kind == kind }
        }?.offset
    }
}
