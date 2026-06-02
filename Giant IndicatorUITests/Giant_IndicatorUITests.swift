//
//  Giant_IndicatorUITests.swift
//  Giant IndicatorUITests
//
//  Created by Nathan Fennel on 6/2/26.
//

import XCTest

#if canImport(UIKit)
import UIKit
#endif

final class Giant_IndicatorUITests: XCTestCase {
    private let resetIndicatorPreferencesArgument = "--ui-testing-reset-indicator-preferences"
    private let batteryLevelArgument = "--ui-testing-battery-level"
    private let playbackStateArgument = "--ui-testing-playback-state"
    private let weatherDeniedArgument = "--ui-testing-weather-denied"
    private let weatherAttributionArgument = "--ui-testing-weather-attribution"
    private let connectivityOverrideArgument = "--ui-testing-connectivity-override"
    private let enabledIndicatorTileIdentifiers = [
        "indicator-tile-weather",
        "indicator-tile-battery",
        "indicator-tile-volume",
        "indicator-tile-playback",
        "indicator-tile-nowPlaying",
        "indicator-tile-wifi",
        "indicator-tile-speaker",
        "indicator-tile-bluetooth",
        "indicator-tile-ringer"
    ]

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testOpenAndCloseSettings() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launch()

        let openSettingsButton = app.buttons["open-settings-button"]
        XCTAssertTrue(openSettingsButton.waitForExistence(timeout: 2))

        openSettingsButton.tap()

        let settingsView = app.otherElements["settings-view"]
        XCTAssertTrue(settingsView.waitForExistence(timeout: 2))

        app.buttons["Done"].tap()

        XCTAssertFalse(settingsView.waitForExistence(timeout: 1))
        XCTAssertTrue(openSettingsButton.waitForExistence(timeout: 2))
    }

    @MainActor
    func testIndicatorVisibilityPersistsAcrossRelaunch() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launch()

        let openSettingsButton = app.buttons["open-settings-button"]
        XCTAssertTrue(openSettingsButton.waitForExistence(timeout: 2))
        openSettingsButton.tap()

        let batteryToggle = app.switches["indicator-toggle-battery"]
        XCTAssertTrue(batteryToggle.waitForExistence(timeout: 2))
        XCTAssertEqual(batteryToggle.value as? String, "1")
        batteryToggle.tap()
        XCTAssertEqual(batteryToggle.value as? String, "0")

        app.buttons["Done"].tap()
        XCTAssertFalse(app.otherElements["indicator-tile-battery"].exists)

        app.terminate()

        app.launchArguments = []
        app.launch()

        XCTAssertTrue(openSettingsButton.waitForExistence(timeout: 2))
        openSettingsButton.tap()

        XCTAssertTrue(batteryToggle.waitForExistence(timeout: 2))
        XCTAssertEqual(batteryToggle.value as? String, "0")
        app.buttons["Done"].tap()
        XCTAssertFalse(app.otherElements["indicator-tile-battery"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testBatteryTileShowsConfiguredPercentage() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += [batteryLevelArgument, "64"]
        app.launch()

        let batteryTile = app.otherElements["indicator-tile-battery"]
        XCTAssertTrue(batteryTile.waitForExistence(timeout: 2))

        let percentageLabel = app.staticTexts["battery-percentage-label"]
        XCTAssertTrue(percentageLabel.waitForExistence(timeout: 2))
        XCTAssertEqual(percentageLabel.label, "64%")
    }

    @MainActor
    func testPlaybackTileShowsPlayingState() throws {
        assertPlaybackState("playing", expectedTitle: "Playing")
    }

    @MainActor
    func testPlaybackTileShowsPausedState() throws {
        assertPlaybackState("paused", expectedTitle: "Paused")
    }

    @MainActor
    func testPlaybackTileShowsStoppedState() throws {
        assertPlaybackState("stopped", expectedTitle: "Stopped")
    }

    @MainActor
    func testPlaybackTileShowsUnavailableFallback() throws {
        assertPlaybackState("unavailable", expectedTitle: "--", expectedSubtitle: "Unavailable")
    }

    @MainActor
    func testNowPlayingTileShowsActiveMetadata() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += [
            "--ui-testing-now-playing-title", "Test Track",
            "--ui-testing-now-playing-artist", "Test Artist",
            "--ui-testing-now-playing-album", "Test Album"
        ]
        app.launch()

        let tile = app.otherElements["indicator-tile-nowPlaying"]
        XCTAssertTrue(tile.waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["now-playing-title-label"].label, "Test Track")
        XCTAssertEqual(app.staticTexts["now-playing-artist-label"].label, "Test Artist")
        XCTAssertEqual(app.staticTexts["now-playing-album-label"].label, "Test Album")
    }

    @MainActor
    func testNowPlayingTileShowsInactiveFallback() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += ["--ui-testing-now-playing", "inactive"]
        app.launch()

        let tile = app.otherElements["indicator-tile-nowPlaying"]
        XCTAssertTrue(tile.waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["now-playing-title-label"].label, "Nothing Playing")
        XCTAssertEqual(app.staticTexts["now-playing-artist-label"].label, "No Active Media")
        XCTAssertFalse(app.staticTexts["now-playing-album-label"].exists)
    }

    @MainActor
    func testWeatherTileShowsDeniedLocationDisclosure() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += [weatherDeniedArgument]
        app.launch()

        let weatherTile = app.otherElements["indicator-tile-weather"]
        XCTAssertTrue(weatherTile.waitForExistence(timeout: 2))

        let weatherValue = app.staticTexts["weather-value-label"]
        XCTAssertTrue(weatherValue.waitForExistence(timeout: 2))
        XCTAssertEqual(weatherValue.label, "Location access is off. Turn on Location Services in Settings to see local weather.")

        let weatherSubtitle = app.staticTexts["weather-subtitle-label"]
        XCTAssertTrue(weatherSubtitle.waitForExistence(timeout: 2))
        XCTAssertEqual(weatherSubtitle.label, "Location access is off")
    }

    @MainActor
    func testWeatherTileShowsAttributionView() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += [weatherAttributionArgument]
        app.launch()

        let weatherTile = app.otherElements["indicator-tile-weather"]
        XCTAssertTrue(weatherTile.waitForExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["weather-attribution-view"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testMasonryLayoutShowsAllEnabledTilesWithoutScrollingInCompactSize() throws {
        #if canImport(UIKit)
        try assertMasonryDashboardLayout(interfaceOrientation: .portrait)
        #else
        try assertMasonryDashboardLayout()
        #endif
    }

    @MainActor
    func testMasonryLayoutShowsAllEnabledTilesWithoutScrollingInRegularSize() throws {
        #if canImport(UIKit)
        try assertMasonryDashboardLayout(interfaceOrientation: .landscapeLeft)
        #else
        try assertMasonryDashboardLayout()
        #endif
    }

    @MainActor
    func testMasonryLayoutReflowsAfterOrientationAndVisibilityChanges() throws {
        #if canImport(UIKit)
        XCUIDevice.shared.orientation = .portrait
        #endif

        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += [
            weatherDeniedArgument,
            batteryLevelArgument, "81",
            playbackStateArgument, "playing",
            "--ui-testing-volume-level", "35",
            connectivityOverrideArgument,
            "--ui-testing-wifi-status", "connected",
            "--ui-testing-speaker-status", "speaker",
            "--ui-testing-bluetooth-status", "off",
            "--ui-testing-ringer-status", "silent"
        ]
        app.launch()

        XCTAssertTrue(app.buttons["open-settings-button"].waitForExistence(timeout: 3))
        assertDashboardHasNoScrollView(app)
        assertAllEnabledTilesAreVisible(app)

        #if canImport(UIKit)
        XCUIDevice.shared.orientation = .landscapeLeft
        #endif
        assertAllEnabledTilesAreVisible(app)

        app.buttons["open-settings-button"].tap()
        let batteryToggle = app.switches["indicator-toggle-battery"]
        XCTAssertTrue(batteryToggle.waitForExistence(timeout: 2))
        batteryToggle.tap()
        app.buttons["Done"].tap()
        XCTAssertFalse(app.otherElements["indicator-tile-battery"].exists)
        assertDashboardHasNoScrollView(app)

        app.buttons["open-settings-button"].tap()
        XCTAssertTrue(batteryToggle.waitForExistence(timeout: 2))
        batteryToggle.tap()
        app.buttons["Done"].tap()

        assertDashboardHasNoScrollView(app)
        assertAllEnabledTilesAreVisible(app)
    }

    @MainActor
    func testConnectivityTilesShowConfiguredState() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += [
            connectivityOverrideArgument,
            "--ui-testing-wifi-status", "connected",
            "--ui-testing-wifi-signal", "72",
            "--ui-testing-speaker-status", "headphones",
            "--ui-testing-bluetooth-status", "off",
            "--ui-testing-ringer-status", "silent"
        ]
        app.launch()

        XCTAssertTrue(app.otherElements["indicator-tile-wifi"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["wifi-value-label"].label, "72%")
        XCTAssertEqual(app.staticTexts["wifi-subtitle-label"].label, "Connected")

        XCTAssertTrue(app.otherElements["indicator-tile-speaker"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["speaker-value-label"].label, "Headphones")
        XCTAssertEqual(app.staticTexts["speaker-subtitle-label"].label, "Wired output")

        XCTAssertTrue(app.otherElements["indicator-tile-bluetooth"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["bluetooth-value-label"].label, "Off")
        XCTAssertEqual(app.staticTexts["bluetooth-subtitle-label"].label, "Bluetooth disabled")

        XCTAssertTrue(app.otherElements["indicator-tile-ringer"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["ringer-value-label"].label, "Silent")
        XCTAssertEqual(app.staticTexts["ringer-subtitle-label"].label, "Muted alerts")
    }

    private func configuredApp(resetIndicatorPreferences: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        if resetIndicatorPreferences {
            app.launchArguments = [resetIndicatorPreferencesArgument]
        }
        return app
    }

    #if canImport(UIKit)
    @MainActor
    private func assertMasonryDashboardLayout(interfaceOrientation: UIDeviceOrientation) throws {
        XCUIDevice.shared.orientation = interfaceOrientation
        try assertMasonryDashboardLayout()
    }
    #endif

    @MainActor
    private func assertMasonryDashboardLayout() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += [
            // Keep weather deterministic in UI tests.
            weatherDeniedArgument,
            batteryLevelArgument, "50",
            playbackStateArgument, "playing",
            "--ui-testing-now-playing-title", "Test Track",
            "--ui-testing-now-playing-artist", "Test Artist",
            "--ui-testing-volume-level", "30",
            connectivityOverrideArgument,
            "--ui-testing-wifi-status", "connected",
            "--ui-testing-speaker-status", "speaker",
            "--ui-testing-bluetooth-status", "off",
            "--ui-testing-ringer-status", "silent"
        ]

        app.launch()

        XCTAssertTrue(app.buttons["open-settings-button"].waitForExistence(timeout: 3))

        XCTAssertEqual(
            app.scrollViews.count, 0,
            "Dashboard masonry layout must not rely on scrolling (PR-9)."
        )

        assertAllEnabledTilesAreVisible(app)
    }

    private func assertPlaybackState(
        _ state: String,
        expectedTitle: String,
        expectedSubtitle: String? = nil
    ) {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += [playbackStateArgument, state]
        app.launch()

        let playbackTile = app.otherElements["indicator-tile-playback"]
        XCTAssertTrue(playbackTile.waitForExistence(timeout: 2))

        let stateLabel = app.staticTexts["playback-state-label"]
        XCTAssertTrue(stateLabel.waitForExistence(timeout: 2))
        XCTAssertEqual(stateLabel.label, expectedTitle)

        if let expectedSubtitle {
            let subtitleLabel = app.staticTexts["playback-subtitle-label"]
            XCTAssertTrue(subtitleLabel.waitForExistence(timeout: 2))
            XCTAssertEqual(subtitleLabel.label, expectedSubtitle)
        }
    }

    private func assertDashboardHasNoScrollView(_ app: XCUIApplication) {
        XCTAssertEqual(
            app.scrollViews.count,
            0,
            "Dashboard masonry layout must not rely on scrolling (PR-9/PR-10)."
        )
    }

    private func assertAllEnabledTilesAreVisible(_ app: XCUIApplication) {
        for tileIdentifier in enabledIndicatorTileIdentifiers {
            let tile = app.otherElements[tileIdentifier]
            XCTAssertTrue(
                tile.waitForExistence(timeout: 3),
                "Expected enabled tile \(tileIdentifier) to exist."
            )
            XCTAssertTrue(
                tile.isHittable,
                "Expected enabled tile \(tileIdentifier) to be on-screen and hittable."
            )
        }
    }
}
