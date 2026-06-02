//
//  Giant_IndicatorApp.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

@main
struct Giant_IndicatorApp: App {
    @StateObject private var weatherViewModel = WeatherViewModel()

    init() {
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-reset-indicator-preferences") {
            IndicatorPreferences.resetVisibility()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(weatherViewModel)
                .task {
                    await weatherViewModel.refreshOnLaunch()
                }
        }
    }
}
