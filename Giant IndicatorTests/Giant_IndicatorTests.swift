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
import SwiftUI
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

    @Test func batteryStateDescribesPowerConnection() async throws {
        let pluggedIn = BatteryState(percentage: 80, powerConnection: .pluggedIn, availability: .available)
        let unplugged = BatteryState(percentage: 80, powerConnection: .unplugged, availability: .available)

        #expect(pluggedIn.isPluggedIn)
        #expect(!unplugged.isPluggedIn)
        #expect(pluggedIn.powerConnectionText == "Plugged In")
        #expect(unplugged.powerConnectionText == "Unplugged")
    }

    @Test func weatherLocationProvider_mapsPermissionStates() async throws {
        let provider = WeatherLocationProvider()
        #expect(provider.permissionState(from: .notDetermined) == .notRequested)
        #expect(provider.permissionState(from: .denied) == .denied)
        #expect(provider.permissionState(from: .restricted) == .restricted)
        #expect(provider.permissionState(from: .unavailable) == .unavailable)
    }

    @Test func weatherLocationProvider_exposesUserFacingMessages() async throws {
        let provider = WeatherLocationProvider()

        #expect(provider.userVisibleErrorMessage(.denied) == "Location access is off. Turn on Location Services in Settings to see local weather.")
        #expect(provider.userVisibleErrorMessage(.restricted) == "Location access is restricted on this device.")
        #expect(provider.userVisibleErrorMessage(.unavailable) == "Unable to determine your location right now.")
        #expect(provider.userVisibleErrorMessage(.notDetermined) == nil)
        #expect(provider.userVisibleErrorMessage(.authorized(CLLocation(latitude: 0, longitude: 0))) == nil)
    }

    @Test func permissionKind_mapsIndicatorRequirements() async throws {
        #expect(PermissionKind.required(for: .weather) == [.location])
        #expect(PermissionKind.required(for: .bluetooth) == [.bluetooth])
        #expect(PermissionKind.required(for: .battery).isEmpty)
    }

    @Test func permissionEducationPreferences_tracksSeenState() async throws {
        let key = "permission.education.seen.location"
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
        #expect(!PermissionEducationPreferences.hasSeenEducation(for: .location))

        PermissionEducationPreferences.markEducationSeen(for: .location)
        #expect(PermissionEducationPreferences.hasSeenEducation(for: .location))
    }

    @Test func permissionGateCoordinator_cancellingEducationRevertsToggle() async throws {
        let gate = PermissionGateCoordinator()
        var visibility = IndicatorKind.defaultVisibilityState
        visibility[.weather] = false

        gate.setIndicatorVisibility(true, for: .weather, currentVisibility: &visibility)

        #expect(gate.pendingAlert != nil)
        gate.cancelEducation(currentVisibility: &visibility)
        #expect(visibility[.weather] == false)
        #expect(gate.pendingAlert == nil)
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

    @Test func displayPreferences_backgroundAppearanceDefaultsAndPersists() async throws {
        let key = "display.backgroundAppearance"
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
        #expect(DisplayPreferences.backgroundAppearance == .dark)

        DisplayPreferences.backgroundAppearance = .light
        #expect(DisplayPreferences.backgroundAppearance == .light)

        DisplayPreferences.backgroundAppearance = .system
        #expect(DisplayPreferences.backgroundAppearance == .system)
    }

    @Test func dashboardBackgroundAppearance_preferredColorScheme() async throws {
        #expect(DashboardBackgroundAppearance.system.preferredColorScheme == nil)
        #expect(DashboardBackgroundAppearance.light.preferredColorScheme == .light)
        #expect(DashboardBackgroundAppearance.dark.preferredColorScheme == .dark)
    }

    @Test func dashboardPalette_mapsBackgroundAndForegroundForColorScheme() async throws {
        let darkPalette = DashboardPalette(colorScheme: .dark)
        let lightPalette = DashboardPalette(colorScheme: .light)

        #expect(darkPalette.background == .black)
        #expect(darkPalette.foreground == .white)
        #expect(lightPalette.background == .white)
        #expect(lightPalette.foreground == .black)
    }

    @Test func batteryReflectiveBackground_mapsBrightnessAcrossBounds() async throws {
        #expect(BatteryReflectiveBackground.brightness(forPercentage: 0) == 0)
        #expect(BatteryReflectiveBackground.brightness(forPercentage: 9) == 0)
        #expect(BatteryReflectiveBackground.brightness(forPercentage: 10) == 0)
        #expect(BatteryReflectiveBackground.brightness(forPercentage: 100) == 1)
        #expect(BatteryReflectiveBackground.brightness(forPercentage: 55) == 0.5)
    }

    @Test func dashboardPalette_batteryReflectiveUsesContrastingForeground() async throws {
        let low = DashboardPalette(batteryPercentage: 5)
        let high = DashboardPalette(batteryPercentage: 95)

        #expect(low.foreground == .white)
        #expect(high.foreground == .black)
    }

    @Test func displayPreferences_batteryReflectiveBackgroundDefaultsAndPersists() async throws {
        let key = "display.batteryReflectiveBackground"
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
        #expect(!DisplayPreferences.batteryReflectiveBackground)

        DisplayPreferences.batteryReflectiveBackground = true
        #expect(DisplayPreferences.batteryReflectiveBackground)
    }

    @Test func batteryDrivenScreenBrightness_appliesSquaredFormulaWithFloor() async throws {
        #expect(BatteryDrivenScreenBrightness.screenBrightness(forPercentage: 20) == 0.10)
        #expect(BatteryDrivenScreenBrightness.screenBrightness(forPercentage: 40) == 0.16)
        #expect(BatteryDrivenScreenBrightness.screenBrightness(forPercentage: 80) == 0.64)
        #expect(BatteryDrivenScreenBrightness.screenBrightness(forPercentage: 100) == 1.0)
        #expect(BatteryDrivenScreenBrightness.normalizedLevel(forPercentage: 50) == 0.5)
    }

    @Test func screenBrightnessControl_matchesPlatformSupport() async throws {
        #if os(macOS)
        #expect(!ScreenBrightnessControl.isPlatformSupported)
        #expect(
            ScreenBrightnessControl.unavailableReason ==
                "Screen brightness control is not available on macOS."
        )
        #elseif canImport(UIKit)
        #expect(ScreenBrightnessControl.isPlatformSupported)
        #endif
    }

    @Test func displayPreferences_batteryDrivenScreenBrightnessDefaultsAndPersists() async throws {
        let key = "display.batteryDrivenScreenBrightness"
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
        #expect(!DisplayPreferences.batteryDrivenScreenBrightness)

        DisplayPreferences.batteryDrivenScreenBrightness = true
        #expect(DisplayPreferences.batteryDrivenScreenBrightness)
    }

    @Test func indicatorKind_defaultVisibilityMatchesDashboardFavorites() async throws {
        for kind in IndicatorKind.defaultDashboardFavorites {
            #expect(kind.defaultVisibility)
        }

        #expect(!IndicatorKind.playback.defaultVisibility)
        #expect(!IndicatorKind.nowPlaying.defaultVisibility)
        #expect(!IndicatorKind.speaker.defaultVisibility)
        #expect(!IndicatorKind.ringer.defaultVisibility)
        #expect(!IndicatorKind.bluetooth.defaultVisibility)
    }

    @Test func indicatorKind_bluetoothIsDisabledByDefault() async throws {
        #expect(!IndicatorKind.bluetooth.isFeatureEnabled)
        #expect(!IndicatorKind.bluetooth.defaultVisibility)
        #expect(!IndicatorKind.bluetooth.isVisibleInSettings)
        #expect(!IndicatorKind.defaultVisibilityState[.bluetooth, default: true])
    }

    @Test func indicatorPreferences_bluetoothStaysHiddenDespiteStoredPreference() async throws {
        let key = IndicatorKind.bluetooth.visibilityStorageKey
        let defaults = UserDefaults.standard
        let prior = defaults.object(forKey: key)
        defer {
            if let prior {
                defaults.set(prior, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        defaults.set(true, forKey: key)
        let visibility = IndicatorPreferences.loadVisibility()
        #expect(visibility[.bluetooth] == false)

        IndicatorPreferences.setVisibility(true, for: .bluetooth)
        #expect(IndicatorPreferences.loadVisibility()[.bluetooth] == false)
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

    @Test func statusBarVisibilityControl_matchesPlatformSupport() async throws {
        #if os(macOS)
        #expect(!StatusBarVisibilityControl.isPlatformSupported)
        #expect(
            StatusBarVisibilityControl.unavailableReason ==
                "Status bar control is not available on macOS."
        )
        #elseif canImport(UIKit)
        #expect(StatusBarVisibilityControl.isPlatformSupported)
        #endif
    }

    @Test func displayPreferences_showStatusBarDefaultsAndPersists() async throws {
        let key = "display.showStatusBar"
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
        #expect(!DisplayPreferences.showStatusBar)

        DisplayPreferences.showStatusBar = true
        #expect(DisplayPreferences.showStatusBar)
    }

    @Test func displayPreferences_showWiFiNetworkNameDefaultsAndPersists() async throws {
        let key = "display.showWiFiNetworkName"
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
        #expect(!DisplayPreferences.showWiFiNetworkName)

        DisplayPreferences.showWiFiNetworkName = true
        #expect(DisplayPreferences.showWiFiNetworkName)
    }

    @Test func displayPreferences_showClockSecondsDefaultsAndPersists() async throws {
        let key = "display.showClockSeconds"
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
        #expect(!DisplayPreferences.showClockSeconds)

        DisplayPreferences.showClockSeconds = true
        #expect(DisplayPreferences.showClockSeconds)
    }

    @Test func wifiSignalStrengthMapping_normalizesRSSI() async throws {
        #expect(WiFiSignalStrengthMapping.percentage(fromRSSI: -30) == 100)
        #expect(WiFiSignalStrengthMapping.percentage(fromRSSI: -100) == 0)
        #expect(WiFiSignalStrengthMapping.percentage(fromRSSI: -65) == 50)
    }

    @Test func wifiIndicatorState_mapsBarsAndPrimaryValue() async throws {
        let strong = WiFiIndicatorState.connected(signal: .known(percentage: 80))
        #expect(strong.filledBarCount == 4)
        #if os(macOS)
        #expect(strong.primaryValueText == "80%")
        #expect(strong.subtitleText == "Connected")
        #else
        #expect(strong.primaryValueText == "Connected")
        #expect(strong.subtitleText == "Wi-Fi active")
        #expect(!strong.showsSignalStrength)
        #endif

        let disconnected = WiFiIndicatorState.disconnected()
        #expect(disconnected.filledBarCount == 0)
        #expect(disconnected.primaryValueText == "Disconnected")
        #expect(disconnected.subtitleText == "No Wi-Fi link")

        let connectionOnly = WiFiIndicatorState.connected(signal: .notApplicable)
        #expect(connectionOnly.primaryValueText == "Connected")
        #expect(connectionOnly.subtitleText == "Wi-Fi active")
        #expect(!connectionOnly.showsSubtitle || connectionOnly.subtitleText == "Wi-Fi active")
    }

    @Test func wifiIndicatorState_showsNetworkNameAsPrimaryWhenEnabled() async throws {
        let named = WiFiIndicatorState.connected(
            signal: .notApplicable,
            networkName: "Office WiFi",
            showsNetworkName: true
        )
        #expect(named.primaryValueText == "Office WiFi")
        #expect(!named.showsSubtitle)
        #expect(named.displaysNetworkNameAsPrimary)

        let namedWithSignal = WiFiIndicatorState.connected(
            signal: .known(percentage: 72),
            networkName: "Office WiFi",
            showsNetworkName: true
        )
        #expect(namedWithSignal.primaryValueText == "Office WiFi")
        #if os(macOS)
        #expect(namedWithSignal.subtitleText == "72%")
        #expect(namedWithSignal.showsSignalStrength)
        #else
        #expect(namedWithSignal.subtitleText == "")
        #endif

        let prefOff = WiFiIndicatorState.connected(
            signal: .notApplicable,
            networkName: "Office WiFi",
            showsNetworkName: false
        )
        #expect(prefOff.primaryValueText == "Connected")
    }

    @Test func wifiNetworkNameSanitizer_rejectsPseudoValues() async throws {
        #expect(WiFiNetworkNameSanitizer.sanitized("Wi-Fi") == nil)
        #expect(WiFiNetworkNameSanitizer.sanitized("WLAN") == nil)
        #expect(WiFiNetworkNameSanitizer.sanitized("Home") == "Home")
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

    @Test func clockFormatting_omitsSecondsByDefault() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let locale = Locale(identifier: "en_US_POSIX")
        let date = Date(timeIntervalSince1970: 0)

        let text = ClockFormatting.timeText(
            from: date,
            showsSeconds: false,
            calendar: calendar,
            locale: locale
        )

        #expect(!text.isEmpty)
        #expect(text.filter(\.isNumber).count >= 3)
    }

    @Test func clockFormatting_includesSecondsWhenRequested() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let locale = Locale(identifier: "en_US_POSIX")
        let date = Date(timeIntervalSince1970: 0)

        let withoutSeconds = ClockFormatting.timeText(
            from: date,
            showsSeconds: false,
            calendar: calendar,
            locale: locale
        )
        let withSeconds = ClockFormatting.timeText(
            from: date,
            showsSeconds: true,
            calendar: calendar,
            locale: locale
        )

        #expect(withSeconds.count >= withoutSeconds.count)
    }

    @Test func indicatorKind_clockIsVisibleInSettings() async throws {
        #expect(IndicatorKind.clock.isVisibleInSettings)
        #expect(IndicatorKind.clock.platformCapabilityHandling == .supported)
        #expect(IndicatorKind.clock.displayName == "Time")
    }

    @Test func indicatorKind_settingsGroupMapping() async throws {
        #expect(IndicatorKind.battery.settingsGroup == .battery)
        #expect(IndicatorKind.wifi.settingsGroup == .wifi)
        #expect(IndicatorKind.clock.settingsGroup == .timeAndDate)
        #expect(IndicatorKind.date.settingsGroup == .timeAndDate)
        #expect(IndicatorKind.volume.settingsGroup == .media)
        #expect(IndicatorKind.weather.settingsGroup == .weather)

        let batteryKinds = IndicatorKind.visibleInSettings(for: .battery)
        #expect(batteryKinds == [.battery])
        #expect(IndicatorKind.visibleInSettings(for: .timeAndDate).contains(.clock))
        #expect(IndicatorKind.visibleInSettings(for: .timeAndDate).contains(.date))
        #expect(!IndicatorKind.visibleInSettings(for: .connectivity).contains(.bluetooth))
    }

    @Test func dateFormatting_usesLocalizedReadableDate() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let locale = Locale(identifier: "en_US_POSIX")
        let date = Date(timeIntervalSince1970: 0)

        let text = DateFormatting.dateText(
            from: date,
            calendar: calendar,
            locale: locale
        )

        #expect(!text.isEmpty)
        #expect(text.contains("1970") || text.contains("Jan") || text.contains("January"))
    }

    @Test func indicatorKind_dateIsVisibleInSettings() async throws {
        #expect(IndicatorKind.date.isVisibleInSettings)
        #expect(IndicatorKind.date.platformCapabilityHandling == .supported)
        #expect(IndicatorKind.date.displayName == "Date")
    }

    @Test func dateViewModel_onlyPublishesWhenStateChanges() async throws {
        let initial = DateState(dateText: "Wednesday, January 1")
        let changed = DateState(dateText: "Thursday, January 2")
        let provider = DateProviderMock(initialState: initial)
        let viewModel = DateViewModel(provider: provider)
        var emittedStates = [DateState]()
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

private final class DateProviderMock: DateStateProviding {
    let subject = PassthroughSubject<DateState, Never>()
    private let initialState: DateState

    init(initialState: DateState) {
        self.initialState = initialState
    }

    func dateStatePublisher() -> AnyPublisher<DateState, Never> {
        subject.prepend(initialState).eraseToAnyPublisher()
    }
}
