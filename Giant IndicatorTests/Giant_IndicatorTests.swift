//
//  Giant_IndicatorTests.swift
//  Giant IndicatorTests
//
//  Created by Nathan Fennel on 6/2/26.
//

import Testing
import Foundation
import CoreLocation
@testable import Giant_Indicator

struct Giant_IndicatorTests {

    @Test func weatherCachePolicy_refreshWhenNoPriorFetch() async throws {
        #expect(WeatherCachePolicy.shouldRefresh(lastFetchAt: nil, now: Date(timeIntervalSince1970: 10)))
    }

    @Test func weatherCachePolicy_doesNotRefreshInsideThreeHourWindow() async throws {
        let now = Date(timeIntervalSince1970: 10_000)
        let twoHoursAgo = now.addingTimeInterval(-(60 * 60 * 2))

        #expect(!WeatherCachePolicy.shouldRefresh(lastFetchAt: twoHoursAgo, now: now))
    }

    @Test func weatherCachePolicy_refreshesAtThreeHoursOrMore() async throws {
        let now = Date(timeIntervalSince1970: 10_000)
        let threeHoursAgo = now.addingTimeInterval(-(60 * 60 * 3))

        #expect(WeatherCachePolicy.shouldRefresh(lastFetchAt: threeHoursAgo, now: now))
    }

    @Test func weatherCachePolicy_selectsNearestHourlyPoint() async throws {
        let base = Date(timeIntervalSince1970: 1_000)
        let hourly = [
            HourlyForecastPoint(date: base.addingTimeInterval(-3600), temperatureCelsius: 13, symbolName: "cloud"),
            HourlyForecastPoint(date: base.addingTimeInterval(1800), temperatureCelsius: 14, symbolName: "cloud.sun"),
            HourlyForecastPoint(date: base.addingTimeInterval(7200), temperatureCelsius: 15, symbolName: "sun.max")
        ]

        let target = base.addingTimeInterval(2000)
        let nearest = WeatherCachePolicy.nearestHourlyPoint(from: hourly, to: target)

        #expect(nearest?.temperatureCelsius == 14)
    }

    @Test func batteryStateNormalizesAndClampsLevel() async throws {
        let belowRange = BatteryState(percentage: -10, availability: .available)
        let inRange = BatteryState(percentage: 40, availability: .available)
        let aboveRange = BatteryState(percentage: 120, availability: .available)

        #expect(belowRange.normalizedLevel == 0)
        #expect(inRange.normalizedLevel == 0.4)
        #expect(aboveRange.normalizedLevel == 1)
        #expect(inRange.percentageText == "40%")
        #expect(aboveRange.percentageText == "100%")
    }

    @Test func batteryStateFillWidthUsesNormalizedLevel() async throws {
        let battery = BatteryState(percentage: 25, availability: .available)
        let width = battery.fillWidth(in: 240)

        #expect(width == 60)
    }

    @Test func weatherLocationProvider_mapsPermissionStates() async throws {
        let provider = WeatherLocationProvider()
        #expect(provider.permissionState(from: .denied) == .denied)
        #expect(provider.permissionState(from: .restricted) == .restricted)
        #expect(provider.permissionState(from: .unavailable) == .unavailable)
    }

    @Test func weatherLocationProvider_exposesUserFacingMessages() async throws {
        let provider = WeatherLocationProvider()

        #expect(provider.userVisibleErrorMessage(.denied) == "Location access denied. Enable Location Services for local weather.")
        #expect(provider.userVisibleErrorMessage(.restricted) == "Location access is restricted on this device.")
        #expect(provider.userVisibleErrorMessage(.unavailable) == "Location unavailable.")
        #expect(provider.userVisibleErrorMessage(.authorized(CLLocation(latitude: 0, longitude: 0))) == nil)
    }

}
