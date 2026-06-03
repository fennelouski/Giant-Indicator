//
//  Giant_IndicatorApp.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

@main
struct Giant_IndicatorApp: App {
    @StateObject private var weatherViewModel = WeatherViewModel()

    init() {
        #if canImport(UIKit)
        UIDevice.current.isBatteryMonitoringEnabled = true
        #endif

        if ProcessInfo.processInfo.arguments.contains("--ui-testing-reset-indicator-preferences") {
            IndicatorPreferences.resetVisibility()
            DisplayPreferences.reset()
            PermissionEducationPreferences.reset()
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-show-wifi-network-name") {
            DisplayPreferences.showWiFiNetworkName = true
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(weatherViewModel)
                #if os(macOS)
                .frame(minWidth: 520, minHeight: 400)
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 900, height: 600)
        .windowResizability(.contentMinSize)
        #endif
    }
}
