//
//  SettingsView.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @State private var activeArea: SettingsArea = .dashboard
    @Binding var indicatorVisibility: [IndicatorKind: Bool]
    @Binding var keepScreenOn: Bool
    @Binding var backgroundAppearance: DashboardBackgroundAppearance
    @Binding var batteryReflectiveBackground: Bool
    @Binding var batteryDrivenScreenBrightness: Bool
    @Binding var showWiFiNetworkName: Bool
    @Binding var showStatusBar: Bool
    @Binding var showClockSeconds: Bool
    let indicatorKinds: [IndicatorKind]
    @ObservedObject var permissionGate: PermissionGateCoordinator

    private enum SettingsArea: String, CaseIterable, Identifiable {
        case dashboard, screen, battery, wifi, timeAndDate, media, connectivity, weather

        var id: Self { self }

        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .screen: return "Screen"
            case .battery: return "Battery"
            case .wifi: return "Wi-Fi"
            case .timeAndDate: return "Time & Date"
            case .media: return "Media"
            case .connectivity: return "Connectivity"
            case .weather: return "Weather"
            }
        }

        var symbol: String {
            switch self {
            case .dashboard: return "square.grid.2x2.fill"
            case .screen: return "sun.max.fill"
            case .battery: return "battery.100"
            case .wifi: return "wifi"
            case .timeAndDate: return "clock.fill"
            case .media: return "play.fill"
            case .connectivity: return "hifispeaker.fill"
            case .weather: return "cloud.sun.fill"
            }
        }

        var optionalGroup: SettingsGroup? {
            switch self {
            case .media: return .media
            case .connectivity: return .connectivity
            case .weather: return .weather
            default: return nil
            }
        }
    }

    private var availableAreas: [SettingsArea] {
        SettingsArea.allCases.filter { area in
            guard let group = area.optionalGroup else { return true }
            return !visibleKinds(in: group).isEmpty
        }
    }

    private var isClockIndicatorEnabled: Bool {
        indicatorVisibility[.clock, default: true]
    }

    var body: some View {
        settingsPresentation
            .accessibilityIdentifier("settings-view")
            #if os(macOS)
            .frame(minWidth: 900, idealWidth: 980, minHeight: 600, idealHeight: 720)
            #elseif os(visionOS)
            .frame(width: 1000, height: 700)
            #endif
            .alert(
                permissionGate.pendingAlert?.title ?? "",
                isPresented: permissionAlertIsPresented,
                presenting: permissionGate.pendingAlert
            ) { _ in
                Button("Cancel", role: .cancel) {
                    permissionGate.cancelEducation(currentVisibility: &indicatorVisibility)
                }
                .accessibilityIdentifier("permission-education-cancel")
                Button("Continue") {
                    permissionGate.confirmEducation(currentVisibility: &indicatorVisibility)
                }
                .accessibilityIdentifier("permission-education-continue")
            } message: { alert in
                Text(alert.message)
            }
    }

    private var permissionAlertIsPresented: Binding<Bool> {
        Binding(
            get: { permissionGate.pendingAlert != nil },
            set: { if !$0 { permissionGate.cancelEducation(currentVisibility: &indicatorVisibility) } }
        )
    }

    @ViewBuilder
    private var settingsPresentation: some View {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            settingsNavigation.presentationSizing(.page)
        } else {
            settingsNavigation
        }
        #else
        settingsNavigation
        #endif
    }

    private var settingsNavigation: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isWide = geometry.size.width >= (dynamicTypeSize.isAccessibilitySize ? 1040 : 760)
                HStack(spacing: 0) {
                    if isWide {
                        List(selection: Binding<SettingsArea?>(
                            get: { activeArea },
                            set: { if let area = $0 { activeArea = area } }
                        )) {
                            ForEach(availableAreas) { area in
                                Label(area.title, systemImage: area.symbol)
                                    .font(.body.weight(.medium))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.vertical, 4)
                                    .tag(area)
                            }
                        }
                        .listStyle(.sidebar)
                        .environment(\.defaultMinListRowHeight, 44)
                        .frame(width: dynamicTypeSize.isAccessibilitySize ? 340 : 220)
                        Divider()
                    }
                    settingsDetails(isWide: isWide)
                        .scrollContentBackground(.hidden)
                        .background {
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.10), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .background(.background)
                        }
                        .frame(maxWidth: 680)
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("settings-done-button")
                    #if os(macOS)
                    .keyboardShortcut(.cancelAction)
                    #endif
                }
            }
        }
        .onChange(of: availableAreas) { _, areas in
            if !areas.contains(activeArea) {
                activeArea = .dashboard
            }
        }
    }

    private func settingsDetails(isWide: Bool) -> some View {
        List {
            if !isWide {
                Section("Section") {
                    Menu {
                        Picker("Section", selection: $activeArea) {
                            ForEach(availableAreas) { area in
                                Label(area.title, systemImage: area.symbol).tag(area)
                            }
                        }
                    } label: {
                        HStack {
                            Label(activeArea.title, systemImage: activeArea.symbol)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.down")
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, 6)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Settings section")
                    .accessibilityValue(activeArea.title)
                }
            }
            switch activeArea {
            case .dashboard:
                clockPreviewSection
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
                Section("Help") {
                    Link("Support", destination: URL(string: "https://github.com/fennelouski/Giant-Indicator/blob/main/docs/support.md")!)
                    Link("Privacy Policy", destination: URL(string: "https://github.com/fennelouski/Giant-Indicator/blob/main/docs/privacy.md")!)
                }
            case .screen:
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
            case .battery:
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
            case .wifi:
                Section {
                    Toggle(isOn: wiFiNetworkNameBinding) {
                        Label("Show Wi-Fi Network Name", systemImage: "wifi")
                    }
                    .accessibilityIdentifier("display-toggle-show-wifi-network-name")

                    indicatorVisibilityToggles(for: .wifi)
                } header: {
                    Text("Wi-Fi")
                } footer: {
                    Text("Network names require Location Services. On iPhone, iPad and Apple Vision Pro, enable Precise Location. If access is off, Wi-Fi still shows connection status.")
                }
            case .timeAndDate:
                clockPreviewSection
                Section("Time & Date") {
                    Toggle(isOn: $showClockSeconds) {
                        Label("Show Seconds on Clock", systemImage: "clock.badge")
                    }
                    .disabled(!isClockIndicatorEnabled)
                    .accessibilityIdentifier("display-toggle-show-clock-seconds")

                    indicatorVisibilityToggles(for: .timeAndDate)
                }
            case .media:
                indicatorVisibilitySection("Media", group: .media)
            case .connectivity:
                indicatorVisibilitySection("Connectivity", group: .connectivity)
            case .weather:
                indicatorVisibilitySection("Weather", group: .weather)
            }
        }
        .environment(\.defaultMinListRowHeight, 44)
        #if os(iOS) || os(visionOS)
        .listSectionSpacing(.compact)
        #endif
    }

    private var clockPreviewSection: some View {
        let previewHeight: CGFloat = dynamicTypeSize.isAccessibilitySize ? 144 : 112
        let palette = DashboardPalette(colorScheme: backgroundAppearance.preferredColorScheme ?? colorScheme)
        let state = ClockState.current(
            at: Date(timeIntervalSinceReferenceDate: 36_572),
            showsSeconds: showClockSeconds
        )
        return Section {
            GeometryReader { geometry in
                ClockIndicatorTile(
                    clockState: state,
                    metrics: TileMetrics(width: geometry.size.width, height: previewHeight)
                )
                .environment(\.dashboardPalette, palette)
                .allowsHitTesting(false)
                .accessibilityLabel("Clock sample")
                .accessibilityValue(state.timeText)
            }
            .frame(maxWidth: 520)
            .frame(height: previewHeight)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        } header: {
            Text("Clock preview")
        } footer: {
            Text(batteryReflectiveBackground
                 ? "Sample time and base background. Battery-reactive brightness isn’t shown."
                 : "Sample time.")
        }
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

    private var wiFiNetworkNameBinding: Binding<Bool> {
        Binding(
            get: { showWiFiNetworkName },
            set: { value in
                if value {
                    var visibility = indicatorVisibility
                    permissionGate.enableWiFiNetworkName(currentVisibility: &visibility)
                    indicatorVisibility = visibility
                } else {
                    showWiFiNetworkName = false
                }
            }
        )
    }
}
