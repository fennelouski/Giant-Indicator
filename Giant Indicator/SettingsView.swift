//
//  SettingsView.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var indicatorVisibility: [IndicatorKind: Bool]
    @Binding var keepScreenOn: Bool
    @Binding var backgroundAppearance: DashboardBackgroundAppearance
    @Binding var batteryReflectiveBackground: Bool
    @Binding var batteryDrivenScreenBrightness: Bool
    @Binding var showWiFiNetworkName: Bool
    @Binding var showStatusBar: Bool
    @Binding var showClockSeconds: Bool
    let indicatorKinds: [IndicatorKind]
    let permissionGate: PermissionGateCoordinator

    private var isClockIndicatorEnabled: Bool {
        indicatorVisibility[.clock, default: true]
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Dashboard") {
                    Picker(selection: $backgroundAppearance) {
                        ForEach(DashboardBackgroundAppearance.allCases) { appearance in
                            Text(appearance.displayName).tag(appearance)
                        }
                    } label: {
                        Label("Background", systemImage: "circle.lefthalf.filled")
                    }
                    .accessibilityIdentifier("display-picker-background-appearance")
                }

                Section {
                    Toggle(isOn: $keepScreenOn) {
                        Label("Keep Screen On", systemImage: "sun.max.fill")
                    }
                    .accessibilityIdentifier("display-toggle-keep-screen-on")

                    Toggle(isOn: $showStatusBar) {
                        Label("Show Status Bar", systemImage: "iphone")
                    }
                    .disabled(!StatusBarVisibilityControl.isPlatformSupported)
                    .accessibilityIdentifier("display-toggle-show-status-bar")
                } header: {
                    Text("Screen")
                } footer: {
                    if !StatusBarVisibilityControl.isPlatformSupported {
                        Text(StatusBarVisibilityControl.unavailableReason)
                    }
                }

                Section {
                    Toggle(isOn: $batteryReflectiveBackground) {
                        Label("Battery-Reactive Background", systemImage: "battery.100")
                    }
                    .accessibilityIdentifier("display-toggle-battery-reflective-background")

                    Toggle(isOn: $batteryDrivenScreenBrightness) {
                        Label("Battery-Driven Brightness", systemImage: "sun.max")
                    }
                    .disabled(!ScreenBrightnessControl.isPlatformSupported)
                    .accessibilityIdentifier("display-toggle-battery-driven-brightness")

                    indicatorVisibilityToggles(for: .battery)
                } header: {
                    Text("Battery")
                } footer: {
                    if !ScreenBrightnessControl.isPlatformSupported {
                        Text(ScreenBrightnessControl.unavailableReason)
                    }
                }

                Section("Wi-Fi") {
                    Toggle(isOn: $showWiFiNetworkName) {
                        Label("Show Wi-Fi Network Name", systemImage: "wifi")
                    }
                    .accessibilityIdentifier("display-toggle-show-wifi-network-name")

                    indicatorVisibilityToggles(for: .wifi)
                }

                Section("Time & Date") {
                    Toggle(isOn: $showClockSeconds) {
                        Label("Show Seconds on Clock", systemImage: "clock.badge")
                    }
                    .disabled(!isClockIndicatorEnabled)
                    .accessibilityIdentifier("display-toggle-show-clock-seconds")

                    indicatorVisibilityToggles(for: .timeAndDate)
                }

                indicatorVisibilitySection("Media", group: .media)
                indicatorVisibilitySection("Connectivity", group: .connectivity)
                indicatorVisibilitySection("Weather", group: .weather)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .accessibilityIdentifier("settings-view")
    }

    @ViewBuilder
    private func indicatorVisibilitySection(_ title: String, group: SettingsGroup) -> some View {
        let kinds = visibleKinds(in: group)
        if !kinds.isEmpty {
            Section(title) {
                indicatorVisibilityToggles(kinds: kinds)
            }
        }
    }

    @ViewBuilder
    private func indicatorVisibilityToggles(for group: SettingsGroup) -> some View {
        indicatorVisibilityToggles(kinds: visibleKinds(in: group))
    }

    @ViewBuilder
    private func indicatorVisibilityToggles(kinds: [IndicatorKind]) -> some View {
        ForEach(kinds) { kind in
            Toggle(isOn: binding(for: kind)) {
                Label(kind.displayName, systemImage: kind.symbol)
            }
            .accessibilityIdentifier("indicator-toggle-\(kind.rawValue)")
        }
    }

    private func visibleKinds(in group: SettingsGroup) -> [IndicatorKind] {
        indicatorKinds.filter { $0.settingsGroup == group }
    }

    private func binding(for kind: IndicatorKind) -> Binding<Bool> {
        Binding(
            get: { indicatorVisibility[kind, default: kind.defaultVisibility] },
            set: { newValue in
                var visibility = indicatorVisibility
                permissionGate.setIndicatorVisibility(
                    newValue,
                    for: kind,
                    currentVisibility: &visibility
                )
                indicatorVisibility = visibility
            }
        )
    }
}
