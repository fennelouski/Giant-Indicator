//
//  Giant_IndicatorTests.swift
//  Giant IndicatorTests
//
//  Created by Nathan Fennel on 6/2/26.
//

import Testing
import Foundation
import CoreLocation
import Combine
@testable import Giant_Indicator

@MainActor
struct Giant_IndicatorTests {
    private final class BatteryProviderMock: BatteryStateProviding {
        let subject: CurrentValueSubject<BatteryState, Never>

        init(initialState: BatteryState) {
            self.subject = CurrentValueSubject(initialState)
        }

        func batteryStatePublisher() -> AnyPublisher<BatteryState, Never> {
            subject.eraseToAnyPublisher()
        }
    }

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

    @Test func displayPreferences_keepScreenOnDefaultsAndPersists() async throws {
        let key = "display.keepScreenOn"
        let defaults = UserDefaults.standard
        let prior = defaults.object(forKey: key)
        defer {
            if let prior {
                defaults.set(prior, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        defaults.removeObject(forKey: key)
        #expect(DisplayPreferences.keepScreenOn)

        DisplayPreferences.keepScreenOn = false
        #expect(!DisplayPreferences.keepScreenOn)
    }

    @Test func indicatorKind_platformCapabilityVisibility() async throws {
        #expect(IndicatorKind.battery.isVisibleInSettings)
        #expect(IndicatorKind.volume.isVisibleInSettings)

        #if canImport(UIKit)
        #expect(IndicatorKind.ringer.isVisibleInSettings)
        #expect(
            IndicatorKind.ringer.platformCapabilityHandling ==
                .showUnavailableState(reason: "iOS does not expose ringer switch state")
        )
        #else
        #expect(!IndicatorKind.ringer.isVisibleInSettings)
        #expect(IndicatorKind.ringer.platformCapabilityHandling == .hidden)
        #endif
    }

    @Test func indicatorFallbackPresentation_unknownValueText() async throws {
        #expect(IndicatorFallbackPresentation.unknownValueText == "--")
    }

    @Test func batteryState_exposesUnavailableFallbackVisual() async throws {
        let unavailable = BatteryState.unavailable
        #expect(!unavailable.isDataAvailable)
        #expect(unavailable.unavailableSymbolName == "batteryblock.slash")
        #expect(unavailable.unavailableReasonText == "Unavailable")
    }

    @Test func volumeState_exposesUnavailableFallbackVisual() async throws {
        let unavailable = VolumeState.unavailable
        #expect(!unavailable.isDataAvailable)
        #expect(unavailable.unavailableSymbolName == "speaker.slash.fill")
    }

    @Test func playbackState_exposesUnavailableFallbackVisual() async throws {
        let unavailable = PlaybackState.unavailable
        #expect(!unavailable.isDataAvailable)
        #expect(unavailable.unavailableSymbolName == "questionmark.circle")
        #expect(unavailable.titleText == "--")
        #expect(unavailable.unavailableReasonText == "Unavailable")
    }

    @Test func nowPlayingState_activeMetadata() async throws {
        let active = NowPlayingState(
            availability: .active(
                NowPlayingMetadata(title: "Track", artist: "Artist", album: "Album")
            )
        )
        #expect(active.isDataAvailable)
        #expect(active.titleText == "Track")
        #expect(active.artistText == "Artist")
        #expect(active.albumText == "Album")
    }

    @Test func nowPlayingState_inactiveFallback() async throws {
        let inactive = NowPlayingState.inactive
        #expect(inactive.isDataAvailable)
        #expect(inactive.titleText == "Nothing Playing")
        #expect(inactive.artistText == "No Active Media")
        #expect(inactive.albumText == nil)
    }

    @Test func nowPlayingState_exposesUnavailableFallbackVisual() async throws {
        let unavailable = NowPlayingState.unavailable
        #expect(!unavailable.isDataAvailable)
        #expect(unavailable.titleText == "--")
        #expect(unavailable.unavailableReasonText == "Unavailable")
    }

    @Test func connectivityIndicatorState_normalizesUnavailableValueText() async throws {
        let unavailable = ConnectivityIndicatorState.unavailable(
            title: "Wi-Fi",
            subtitle: "Wi-Fi status unavailable",
            symbolName: "wifi.slash",
            reason: "Permission Denied"
        )

        #expect(!unavailable.isDataAvailable)
        #expect(unavailable.displayValueText == "--")
        #expect(unavailable.unavailableReasonText == "Permission Denied")
    }

    @Test func indicatorPlaceholder_fromConnectivityIndicator_marksUnavailableFallback() async throws {
        let placeholder = IndicatorPlaceholder.fromConnectivityIndicator(
            .unavailable(
                title: "Bluetooth",
                subtitle: "Bluetooth permission denied",
                symbolName: "bolt.horizontal",
                reason: "Permission Denied"
            ),
            kind: .bluetooth
        )

        #expect(placeholder.showsUnavailableFallback)
        #expect(placeholder.value == "--")
        #expect(placeholder.subtitle == "Bluetooth permission denied")
    }

    @Test func batteryViewModel_onlyPublishesWhenStateChanges() async throws {
        let initial = BatteryState.unavailable
        let changed = BatteryState(percentage: 55, availability: .available)
        let provider = BatteryProviderMock(initialState: initial)
        let viewModel = BatteryViewModel(provider: provider)
        var emittedStates = [BatteryState]()
        let cancellable = viewModel.$state
            .dropFirst()
            .sink { emittedStates.append($0) }
        defer { cancellable.cancel() }

        provider.subject.send(initial)
        provider.subject.send(initial)
        provider.subject.send(changed)
        provider.subject.send(changed)

        #expect(emittedStates == [changed])
    }

}
