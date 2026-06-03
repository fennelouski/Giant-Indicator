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
    private let batteryPluggedInArgument = "--ui-testing-battery-plugged-in"
    private let batteryUnpluggedArgument = "--ui-testing-battery-unplugged"
    private let playbackStateArgument = "--ui-testing-playback-state"
    private let weatherDeniedArgument = "--ui-testing-weather-denied"
    private let weatherAttributionArgument = "--ui-testing-weather-attribution"
    private let connectivityOverrideArgument = "--ui-testing-connectivity-override"
    private let defaultDashboardTileIdentifiers = [
        "indicator-tile-weather",
        "indicator-tile-battery",
        "indicator-tile-volume",
        "indicator-tile-wifi",
        "indicator-tile-clock",
        "indicator-tile-date"
    ]

    private let defaultDashboardTileCount = 6

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
        tapSwitch("indicator-toggle-battery", in: app)
        XCTAssertTrue(
            waitForSwitchValue("indicator-toggle-battery", expected: "0", in: app, timeout: 2)
        )

        app.buttons["Done"].tap()
        XCTAssertFalse(app.otherElements["indicator-tile-battery"].exists)

        app.terminate()

        app.launchArguments = []
        app.launch()

        XCTAssertTrue(openSettingsButton.waitForExistence(timeout: 2))
        openSettingsButton.tap()

        XCTAssertTrue(batteryToggle.waitForExistence(timeout: 2))
        scrollIntoView(batteryToggle, in: app)
        XCTAssertEqual(app.switches["indicator-toggle-battery"].value as? String, "0")
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
    func testBatteryTileShowsPluggedInStatus() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += [batteryLevelArgument, "72", batteryPluggedInArgument]
        app.launch()

        let powerLabel = app.staticTexts["battery-power-connection-label"]
        XCTAssertTrue(powerLabel.waitForExistence(timeout: 2))
        XCTAssertEqual(powerLabel.label, "Plugged In")
    }

    @MainActor
    func testBatteryTileShowsUnpluggedStatus() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += [batteryLevelArgument, "72", batteryUnpluggedArgument]
        app.launch()

        let powerLabel = app.staticTexts["battery-power-connection-label"]
        XCTAssertTrue(powerLabel.waitForExistence(timeout: 2))
        XCTAssertEqual(powerLabel.label, "Unplugged")
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
    func testWeatherTileShowsNotRequestedBeforeLocationConsent() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launch()

        let weatherTile = app.otherElements["indicator-tile-weather"]
        XCTAssertTrue(weatherTile.waitForExistence(timeout: 2))

        let weatherValue = app.staticTexts["weather-value-label"]
        XCTAssertTrue(weatherValue.waitForExistence(timeout: 2))
        XCTAssertEqual(weatherValue.label, "Weather")

        let weatherSubtitle = app.staticTexts["weather-subtitle-label"]
        XCTAssertTrue(weatherSubtitle.waitForExistence(timeout: 2))
        XCTAssertEqual(weatherSubtitle.label, "Enable in Settings to load weather")
    }

    @MainActor
    func testEnablingWeatherShowsPermissionEducationAlert() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += ["--ui-testing-force-permission-not-determined"]
        app.launch()

        app.buttons["open-settings-button"].tap()
        XCTAssertTrue(app.otherElements["settings-view"].waitForExistence(timeout: 2))

        let weatherToggle = app.switches["indicator-toggle-weather"]
        XCTAssertTrue(weatherToggle.waitForExistence(timeout: 2))
        scrollIntoView(weatherToggle, in: app)
        if weatherToggle.value as? String == "1" {
            weatherToggle.tap()
        }
        weatherToggle.tap()

        let educationAlert = app.alerts["Location Access"]
        XCTAssertTrue(educationAlert.waitForExistence(timeout: 2))
        educationAlert.buttons["Continue"].tap()
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
    func testDefaultDashboardShowsOnlyFavoriteTiles() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += [weatherDeniedArgument]
        app.launch()

        XCTAssertTrue(app.buttons["open-settings-button"].waitForExistence(timeout: 3))
        assertDefaultDashboardTilesAreVisible(app)
        XCTAssertFalse(app.otherElements["indicator-tile-playback"].exists)
        XCTAssertFalse(app.otherElements["indicator-tile-nowPlaying"].exists)
        XCTAssertFalse(app.otherElements["indicator-tile-speaker"].exists)
        XCTAssertFalse(app.otherElements["indicator-tile-ringer"].exists)
    }

    @MainActor
    func testDashboardTilesDoNotOverlapFrames() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += [weatherDeniedArgument]
        app.launch()

        XCTAssertTrue(app.buttons["open-settings-button"].waitForExistence(timeout: 3))
        assertDefaultDashboardTilesAreVisible(app)
        assertDashboardTilesDoNotOverlap(app, tileIdentifiers: defaultDashboardTileIdentifiers)
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
            "--ui-testing-ringer-status", "silent"
        ]
        app.launch()

        XCTAssertTrue(app.buttons["open-settings-button"].waitForExistence(timeout: 3))
        assertDashboardHasNoScrollView(app)
        assertDefaultDashboardTilesAreVisible(app)

        #if canImport(UIKit)
        XCUIDevice.shared.orientation = .landscapeLeft
        #endif
        assertDefaultDashboardTilesAreVisible(app)

        app.buttons["open-settings-button"].tap()
        let batteryToggle = app.switches["indicator-toggle-battery"]
        XCTAssertTrue(batteryToggle.waitForExistence(timeout: 2))
        tapSwitch("indicator-toggle-battery", in: app)
        app.buttons["Done"].tap()
        XCTAssertFalse(app.otherElements["indicator-tile-battery"].exists)
        assertDashboardHasNoScrollView(app)

        app.buttons["open-settings-button"].tap()
        XCTAssertTrue(batteryToggle.waitForExistence(timeout: 2))
        tapSwitch("indicator-toggle-battery", in: app)
        app.buttons["Done"].tap()

        assertDashboardHasNoScrollView(app)
        assertDefaultDashboardTilesAreVisible(app)
    }

    @MainActor
    func testConnectivityTilesShowConfiguredState() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += [
            connectivityOverrideArgument,
            "--ui-testing-wifi-status", "connected",
            "--ui-testing-wifi-signal", "72",
            "--ui-testing-speaker-status", "headphones",
            "--ui-testing-ringer-status", "silent"
        ]
        app.launch()

        enableIndicators(["speaker", "ringer"], in: app)

        XCTAssertTrue(app.otherElements["indicator-tile-wifi"].waitForExistence(timeout: 2))
        #if os(macOS)
        XCTAssertEqual(app.staticTexts["wifi-value-label"].label, "72%")
        XCTAssertEqual(app.staticTexts["wifi-subtitle-label"].label, "Connected")
        #else
        XCTAssertEqual(app.staticTexts["wifi-value-label"].label, "Connected")
        XCTAssertEqual(app.staticTexts["wifi-subtitle-label"].label, "Wi-Fi active")
        #endif

        XCTAssertTrue(app.otherElements["indicator-tile-speaker"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["speaker-value-label"].label, "Headphones")
        XCTAssertEqual(app.staticTexts["speaker-subtitle-label"].label, "Wired output")

        XCTAssertFalse(app.otherElements["indicator-tile-bluetooth"].exists)

        XCTAssertTrue(app.otherElements["indicator-tile-ringer"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["ringer-value-label"].label, "Silent")
        XCTAssertEqual(app.staticTexts["ringer-subtitle-label"].label, "Muted alerts")
    }

    @MainActor
    func testShowStatusBarPreferencePersistsAcrossRelaunch() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launch()

        let openSettingsButton = app.buttons["open-settings-button"]
        XCTAssertTrue(openSettingsButton.waitForExistence(timeout: 2))
        openSettingsButton.tap()

        let statusBarToggle = app.switches["display-toggle-show-status-bar"]
        XCTAssertTrue(statusBarToggle.waitForExistence(timeout: 2))

        #if canImport(UIKit) && !os(macOS)
        XCTAssertEqual(statusBarToggle.value as? String, "0")
        statusBarToggle.tap()
        XCTAssertEqual(statusBarToggle.value as? String, "1")
        #else
        XCTAssertFalse(statusBarToggle.isEnabled)
        #endif

        app.buttons["Done"].tap()
        app.terminate()

        app.launchArguments = []
        app.launch()

        XCTAssertTrue(openSettingsButton.waitForExistence(timeout: 2))
        openSettingsButton.tap()
        XCTAssertTrue(statusBarToggle.waitForExistence(timeout: 2))

        #if canImport(UIKit) && !os(macOS)
        XCTAssertEqual(statusBarToggle.value as? String, "1")
        #else
        XCTAssertFalse(statusBarToggle.isEnabled)
        #endif

        app.buttons["Done"].tap()
    }

    @MainActor
    func testWiFiTileShowsNetworkNameWhenEnabled() throws {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += [
            connectivityOverrideArgument,
            "--ui-testing-wifi-status", "connected",
            "--ui-testing-show-wifi-network-name",
            "--ui-testing-wifi-ssid", "HomeNetwork"
        ]
        app.launch()

        XCTAssertTrue(app.otherElements["indicator-tile-wifi"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["wifi-value-label"].label, "HomeNetwork")
        XCTAssertFalse(app.staticTexts["wifi-subtitle-label"].exists)
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
            weatherDeniedArgument,
            batteryLevelArgument, "50",
            "--ui-testing-volume-level", "30",
            connectivityOverrideArgument,
            "--ui-testing-wifi-status", "connected"
        ]

        app.launch()

        XCTAssertTrue(app.buttons["open-settings-button"].waitForExistence(timeout: 3))

        XCTAssertEqual(
            app.scrollViews.count, 0,
            "Dashboard masonry layout must not rely on scrolling (PR-9)."
        )

        assertDefaultDashboardTilesAreVisible(app)
        assertDashboardTilesDoNotOverlap(app, tileIdentifiers: defaultDashboardTileIdentifiers)
    }

    private func assertPlaybackState(
        _ state: String,
        expectedTitle: String,
        expectedSubtitle: String? = nil
    ) {
        let app = configuredApp(resetIndicatorPreferences: true)
        app.launchArguments += [playbackStateArgument, state]
        app.launch()

        enableIndicators(["playback"], in: app)

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

    private func assertDefaultDashboardTilesAreVisible(_ app: XCUIApplication) {
        var visibleCount = 0
        for tileIdentifier in defaultDashboardTileIdentifiers {
            let tile = app.otherElements[tileIdentifier]
            XCTAssertTrue(
                tile.waitForExistence(timeout: 3),
                "Expected default dashboard tile \(tileIdentifier) to exist."
            )
            XCTAssertTrue(
                tile.isHittable,
                "Expected default dashboard tile \(tileIdentifier) to be on-screen and hittable."
            )
            visibleCount += 1
        }
        XCTAssertEqual(visibleCount, defaultDashboardTileCount)
    }

    private func assertDashboardTilesDoNotOverlap(
        _ app: XCUIApplication,
        tileIdentifiers: [String]
    ) {
        var frames: [CGRect] = []
        for tileIdentifier in tileIdentifiers {
            let tile = app.otherElements[tileIdentifier]
            XCTAssertTrue(tile.exists)
            frames.append(tile.frame)
        }

        for firstIndex in frames.indices {
            for secondIndex in frames.indices where secondIndex > firstIndex {
                let overlap = frames[firstIndex].intersection(frames[secondIndex])
                let overlapsMeaningfully = !overlap.isNull && overlap.width > 1 && overlap.height > 1
                XCTAssertFalse(
                    overlapsMeaningfully,
                    "Tiles \(tileIdentifiers[firstIndex]) and \(tileIdentifiers[secondIndex]) overlap."
                )
            }
        }
    }

    private func enableIndicators(_ kinds: [String], in app: XCUIApplication) {
        let openSettingsButton = app.buttons["open-settings-button"]
        XCTAssertTrue(openSettingsButton.waitForExistence(timeout: 2))
        openSettingsButton.tap()

        for kind in kinds {
            let toggle = app.switches["indicator-toggle-\(kind)"]
            XCTAssertTrue(toggle.waitForExistence(timeout: 2))
            if (toggle.value as? String) == "0" {
                tapSwitch("indicator-toggle-\(kind)", in: app)
            }
        }

        app.buttons["Done"].tap()
    }

    private func scrollIntoView(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 10) {
        guard element.waitForExistence(timeout: 2) else { return }
        let scrollView = app.tables.firstMatch
        guard scrollView.waitForExistence(timeout: 2) else { return }

        var swipes = 0
        while swipes < maxSwipes {
            if element.isHittable {
                return
            }
            scrollView.swipeUp()
            swipes += 1
        }

        swipes = 0
        while swipes < maxSwipes {
            if element.isHittable {
                return
            }
            scrollView.swipeDown()
            swipes += 1
        }
    }

    private func tapSwitch(_ identifier: String, in app: XCUIApplication) {
        scrollIntoView(app.switches[identifier], in: app)
        let toggle = app.switches[identifier]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2))
        XCTAssertTrue(toggle.isHittable)
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
    }

    private func waitForSwitchValue(
        _ identifier: String,
        expected: String,
        in app: XCUIApplication,
        timeout: TimeInterval
    ) -> Bool {
        let toggle = app.switches[identifier]
        let predicate = NSPredicate(format: "value == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: toggle)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
