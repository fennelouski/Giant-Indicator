//
//  Giant_IndicatorUITests.swift
//  Giant IndicatorUITests
//
//  Created by Nathan Fennel on 6/2/26.
//

import XCTest

final class Giant_IndicatorUITests: XCTestCase {
    private let resetIndicatorPreferencesArgument = "--ui-testing-reset-indicator-preferences"
    private let batteryLevelArgument = "--ui-testing-battery-level"
    private let playbackStateArgument = "--ui-testing-playback-state"
    private let weatherDeniedArgument = "--ui-testing-weather-denied"
    private let weatherAttributionArgument = "--ui-testing-weather-attribution"

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
    func testWeatherTileShowsDeniedLocationDisclosure() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += [weatherDeniedArgument]
        app.launch()

        let weatherTile = app.otherElements["indicator-tile-weather"]
        XCTAssertTrue(weatherTile.waitForExistence(timeout: 2))

        let weatherValue = app.staticTexts["weather-value-label"]
        XCTAssertTrue(weatherValue.waitForExistence(timeout: 2))
        XCTAssertEqual(weatherValue.label, "Location access denied. Enable Location Services for local weather.")

        let weatherSubtitle = app.staticTexts["weather-subtitle-label"]
        XCTAssertTrue(weatherSubtitle.waitForExistence(timeout: 2))
        XCTAssertEqual(weatherSubtitle.label, "Location permission denied")
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

    private func configuredApp(resetIndicatorPreferences: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        if resetIndicatorPreferences {
            app.launchArguments = [resetIndicatorPreferencesArgument]
        }
        return app
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
}
