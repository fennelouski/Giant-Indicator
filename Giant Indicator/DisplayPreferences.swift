//
//  DisplayPreferences.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import Foundation

enum DisplayPreferences {
    static let defaults = UserDefaults.standard
    private static let keepScreenOnKey = "display.keepScreenOn"
    private static let backgroundAppearanceKey = "display.backgroundAppearance"
    private static let batteryReflectiveBackgroundKey = "display.batteryReflectiveBackground"
    private static let batteryDrivenScreenBrightnessKey = "display.batteryDrivenScreenBrightness"
    private static let showWiFiNetworkNameKey = "display.showWiFiNetworkName"
    private static let showStatusBarKey = "display.showStatusBar"
    private static let showClockSecondsKey = "display.showClockSeconds"
    private static let batteryTileDisplayStyleKey = "display.batteryTileDisplayStyle"

    /// Defaults to enabled: the dashboard is meant to stay visible across the room (PR-14).
    static var keepScreenOn: Bool {
        get {
            guard defaults.object(forKey: keepScreenOnKey) != nil else {
                return true
            }
            return defaults.bool(forKey: keepScreenOnKey)
        }
        set {
            defaults.set(newValue, forKey: keepScreenOnKey)
        }
    }

    /// Defaults to dark to preserve the original black dashboard (PR-1) until the user changes it (PR-20).
    static var backgroundAppearance: DashboardBackgroundAppearance {
        get {
            guard
                let raw = defaults.string(forKey: backgroundAppearanceKey),
                let appearance = DashboardBackgroundAppearance(rawValue: raw)
            else {
                return .dark
            }
            return appearance
        }
        set {
            defaults.set(newValue.rawValue, forKey: backgroundAppearanceKey)
        }
    }

    /// Defaults to off; when enabled, dashboard background brightness follows battery level (PR-21).
    static var batteryReflectiveBackground: Bool {
        get {
            guard defaults.object(forKey: batteryReflectiveBackgroundKey) != nil else {
                return false
            }
            return defaults.bool(forKey: batteryReflectiveBackgroundKey)
        }
        set {
            defaults.set(newValue, forKey: batteryReflectiveBackgroundKey)
        }
    }

    /// Defaults to off; when enabled, system screen brightness follows battery level (PR-22).
    static var batteryDrivenScreenBrightness: Bool {
        get {
            guard defaults.object(forKey: batteryDrivenScreenBrightnessKey) != nil else {
                return false
            }
            return defaults.bool(forKey: batteryDrivenScreenBrightnessKey)
        }
        set {
            defaults.set(newValue, forKey: batteryDrivenScreenBrightnessKey)
        }
    }

    /// Defaults to off; when enabled, shows the connected Wi-Fi network name when the platform provides it.
    static var showWiFiNetworkName: Bool {
        get {
            guard defaults.object(forKey: showWiFiNetworkNameKey) != nil else {
                return false
            }
            return defaults.bool(forKey: showWiFiNetworkNameKey)
        }
        set {
            defaults.set(newValue, forKey: showWiFiNetworkNameKey)
        }
    }

    /// Defaults to off; when enabled, the time tile includes seconds (PR-25).
    static var showClockSeconds: Bool {
        get {
            guard defaults.object(forKey: showClockSecondsKey) != nil else {
                return false
            }
            return defaults.bool(forKey: showClockSecondsKey)
        }
        set {
            defaults.set(newValue, forKey: showClockSecondsKey)
        }
    }

    /// Defaults to standard; tap battery percentage on the dashboard to cycle styles.
    static var batteryTileDisplayStyle: BatteryTileDisplayStyle {
        get {
            guard
                let raw = defaults.string(forKey: batteryTileDisplayStyleKey),
                let style = BatteryTileDisplayStyle(rawValue: raw)
            else {
                return .standard
            }
            return style
        }
        set {
            defaults.set(newValue.rawValue, forKey: batteryTileDisplayStyleKey)
        }
    }

    /// Defaults to off; when enabled, shows the system status bar on supported platforms (PR-23).
    static var showStatusBar: Bool {
        get {
            guard defaults.object(forKey: showStatusBarKey) != nil else {
                return false
            }
            return defaults.bool(forKey: showStatusBarKey)
        }
        set {
            defaults.set(newValue, forKey: showStatusBarKey)
        }
    }

    static func reset() {
        defaults.removeObject(forKey: keepScreenOnKey)
        defaults.removeObject(forKey: backgroundAppearanceKey)
        defaults.removeObject(forKey: batteryReflectiveBackgroundKey)
        defaults.removeObject(forKey: batteryDrivenScreenBrightnessKey)
        defaults.removeObject(forKey: showWiFiNetworkNameKey)
        defaults.removeObject(forKey: showStatusBarKey)
        defaults.removeObject(forKey: showClockSecondsKey)
        defaults.removeObject(forKey: batteryTileDisplayStyleKey)
    }
}
