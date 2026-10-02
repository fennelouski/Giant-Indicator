import XCTest

final class GiantIndicatorReleaseUITests: XCTestCase {
    @MainActor
    func testMacSettingsPersistAndCapture() throws {
        #if os(macOS)
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["GIANT_INDICATOR_QA_DEFAULTS_SUITE"] = "giant-indicator.qa.release-mac"
        app.launchArguments = ["--ui-testing-reset-indicator-preferences"]
        app.launch()
        XCTAssertTrue(app.buttons["open-settings-button"].waitForExistence(timeout: 10))
        capture("mac-01-default", app: app)
        app.typeKey(",", modifierFlags: .command)
        XCTAssertTrue(app.buttons["settings-done-button"].waitForExistence(timeout: 5))
        capture("mac-02-settings-dashboard", app: app)
        select("Time & Date", in: app)
        let seconds = app.checkBoxes["display-toggle-show-clock-seconds"]
        XCTAssertTrue(seconds.waitForExistence(timeout: 3))
        if seconds.value as? String != "1" { seconds.click() }
        XCTAssertEqual(seconds.value as? String, "1")
        capture("mac-03-clock-preview", app: app)
        app.buttons["settings-done-button"].click()
        capture("mac-04-clock-seconds", app: app)
        app.terminate()
        app.launchArguments = []
        app.launch()
        app.buttons["open-settings-button"].click()
        select("Time & Date", in: app)
        XCTAssertEqual(app.checkBoxes["display-toggle-show-clock-seconds"].value as? String, "1")
        select("Screen", in: app)
        XCTAssertFalse(app.checkBoxes["display-toggle-show-status-bar"].isEnabled)
        capture("mac-05-screen", app: app)
        select("Battery", in: app)
        XCTAssertFalse(app.checkBoxes["display-toggle-battery-driven-brightness"].isEnabled)
        capture("mac-06-battery-settings", app: app)
        select("Media", in: app)
        let volume = app.checkBoxes["indicator-toggle-volume"]
        XCTAssertTrue(volume.waitForExistence(timeout: 3))
        if volume.value as? String != "1" { volume.click() }
        XCTAssertFalse(app.checkBoxes["indicator-toggle-playback"].exists)
        XCTAssertFalse(app.checkBoxes["indicator-toggle-nowPlaying"].exists)
        capture("mac-07-volume-settings", app: app)
        app.buttons["settings-done-button"].click()
        capture("mac-08-volume-dashboard", app: app)
        app.buttons["open-settings-button"].click()
        select("Wi-Fi", in: app)
        let wifi = app.checkBoxes["indicator-toggle-wifi"]
        if wifi.value as? String != "1" { wifi.click() }
        let networkName = app.checkBoxes["display-toggle-show-wifi-network-name"]
        networkName.click()
        let cancelPermission = app.buttons["permission-education-cancel"]
        if cancelPermission.waitForExistence(timeout: 3) {
            cancelPermission.click()
        } else {
            XCTAssertEqual(networkName.value as? String, "1")
            networkName.click()
        }
        XCTAssertEqual(networkName.value as? String, "0")
        capture("mac-09-wifi-settings", app: app)
        app.buttons["settings-done-button"].click()
        capture("mac-10-connected-dashboard", app: app)
        app.buttons["open-settings-button"].click()
        app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: [])
        XCTAssertFalse(app.buttons["settings-done-button"].waitForExistence(timeout: 1))
        app.terminate()
        #else
        throw XCTSkip("Native Mac release workflow; Vision is verified in its own Simulator.")
        #endif
    }

    @MainActor private func select(_ title: String, in app: XCUIApplication) {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", title))
            .firstMatch.click()
    }

    @MainActor private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
