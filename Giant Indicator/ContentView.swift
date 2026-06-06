import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var weatherViewModel: WeatherViewModel
    @StateObject private var permissionGate = PermissionGateCoordinator()
    @StateObject private var settingsHintPresenter = SettingsHintPresenter()
    @State private var isSettingsPresented = false
    @State private var indicatorVisibility: [IndicatorKind: Bool] = IndicatorPreferences.loadVisibility()
    @State private var keepScreenOn = DisplayPreferences.keepScreenOn
    @State private var backgroundAppearance = DisplayPreferences.backgroundAppearance
    @State private var batteryReflectiveBackground = DisplayPreferences.batteryReflectiveBackground
    @State private var batteryDrivenScreenBrightness = DisplayPreferences.batteryDrivenScreenBrightness
    @State private var showWiFiNetworkName = DisplayPreferences.showWiFiNetworkName
    @State private var showStatusBar = DisplayPreferences.showStatusBar
    @State private var showClockSeconds = DisplayPreferences.showClockSeconds
    @StateObject private var batteryViewModel = BatteryViewModel()
    @StateObject private var volumeViewModel = VolumeViewModel()
    @StateObject private var playbackViewModel = PlaybackViewModel()
    @StateObject private var nowPlayingViewModel = NowPlayingViewModel()
    @StateObject private var connectivityViewModel = ConnectivityViewModel()
    @StateObject private var clockViewModel = ClockViewModel(
        showsSeconds: DisplayPreferences.showClockSeconds
    )
    @StateObject private var dateViewModel = DateViewModel()

    private var indicators: [IndicatorPlaceholder] {
        [
            IndicatorPlaceholder(kind: .battery, value: batteryViewModel.state.percentageText),
            IndicatorPlaceholder.fromBatteryChargingState(batteryViewModel.state),
            IndicatorPlaceholder(kind: .volume, value: volumeViewModel.state.percentageText),
            IndicatorPlaceholder(kind: .playback, value: playbackViewModel.state.titleText),
            IndicatorPlaceholder(kind: .nowPlaying, value: nowPlayingViewModel.state.titleText),
            IndicatorPlaceholder.fromWiFiState(connectivityViewModel.state.wifi),
            IndicatorPlaceholder.fromConnectivityIndicator(
                connectivityViewModel.state.speaker,
                kind: .speaker
            ),
            IndicatorPlaceholder.fromConnectivityIndicator(
                connectivityViewModel.state.bluetooth,
                kind: .bluetooth
            ),
            IndicatorPlaceholder.fromConnectivityIndicator(
                connectivityViewModel.state.ringer,
                kind: .ringer
            ),
            IndicatorPlaceholder.fromWeatherState(weatherViewModel.displayState),
            IndicatorPlaceholder(kind: .clock, value: clockViewModel.state.timeText),
            IndicatorPlaceholder(kind: .date, value: dateViewModel.state.dateText)
        ]
    }

    private var visibleIndicators: [IndicatorPlaceholder] {
        indicators.filter { placeholder in
            isIndicatorVisible(placeholder.kind) &&
                placeholder.kind.platformCapabilityHandling != .hidden
        }
    }

    private var settingsIndicatorKinds: [IndicatorKind] {
        IndicatorKind.allCases.filter(\.isVisibleInSettings)
    }

    var body: some View {
        GeometryReader { rootProxy in
            ZStack {
                dashboardBackground
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .gesture(backgroundTapGesture)

                if visibleIndicators.isEmpty {
                    EmptyIndicatorsView()
                } else {
                    GeometryReader { proxy in
                        let layout = MasonryLayoutPlan.build(
                            indicators: visibleIndicators,
                            in: proxy.size
                        )

                        HStack(alignment: .top, spacing: layout.spacing) {
                            ForEach(Array(layout.columns.enumerated()), id: \.offset) { _, column in
                                VStack(spacing: layout.spacing) {
                                    ForEach(column.items) { item in
                                        let metrics = TileMetrics(width: item.width, height: item.height)
                                        tileView(
                                            for: item.placeholder,
                                            metrics: metrics,
                                            showsKindLabel: item.showsKindLabel
                                        )
                                        .frame(height: item.height)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .top)
                            }
                        }
                        .padding(layout.outerPadding)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .animation(.easeInOut(duration: 0.2), value: layout.layoutSignature)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if settingsHintPresenter.isVisible {
                    SettingsHintToast(message: SettingsHintPresenter.message)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: settingsHintPresenter.isVisible)
            .contentShape(Rectangle())
            .simultaneousGesture(doubleTapToOpenSettingsGesture)
            .simultaneousGesture(longPressHintGesture)
            .simultaneousGesture(edgePanHintGesture(in: rootProxy.size))
            .accessibilityHint("Double tap anywhere to open settings")
            .accessibilityAction(named: "Open Settings") {
                isSettingsPresented = true
            }
        }
        .keepScreenAwake(keepScreenOn)
        .statusBarVisibility(showStatusBar)
        .batteryDrivenScreenBrightness(
            isEnabled: batteryDrivenScreenBrightness,
            batteryPercentage: batteryViewModel.state.percentage,
            isDataAvailable: batteryViewModel.state.isDataAvailable
        )
        .onChange(of: keepScreenOn) { _, newValue in
            DisplayPreferences.keepScreenOn = newValue
        }
        .onChange(of: backgroundAppearance) { _, newValue in
            DisplayPreferences.backgroundAppearance = newValue
        }
        .onChange(of: batteryReflectiveBackground) { _, newValue in
            DisplayPreferences.batteryReflectiveBackground = newValue
        }
        .onChange(of: batteryDrivenScreenBrightness) { _, newValue in
            DisplayPreferences.batteryDrivenScreenBrightness = newValue
        }
        .onChange(of: showWiFiNetworkName) { _, newValue in
            DisplayPreferences.showWiFiNetworkName = newValue
            connectivityViewModel.updateShowWiFiNetworkName(newValue)
        }
        .onChange(of: showStatusBar) { _, newValue in
            DisplayPreferences.showStatusBar = newValue
        }
        .onChange(of: showClockSeconds) { _, newValue in
            DisplayPreferences.showClockSeconds = newValue
            clockViewModel.updateShowsSeconds(newValue)
        }
        .preferredColorScheme(
            batteryReflectiveBackground ? nil : backgroundAppearance.preferredColorScheme
        )
        .dashboardPaletteEnvironment(
            backgroundAppearance: backgroundAppearance,
            batteryReflectiveBackground: batteryReflectiveBackground,
            batteryPercentage: batteryViewModel.state.percentage,
            batteryDataAvailable: batteryViewModel.state.isDataAvailable
        )
        .animation(
            batteryReflectiveBackground ? .easeInOut(duration: 0.35) : nil,
            value: batteryViewModel.state.percentage
        )
        .onAppear {
            configurePermissionGateHandlers()
        }
        .task {
            syncBluetoothMonitoring()
            await syncWeatherState()
        }
        .onChange(of: indicatorVisibility) { _, _ in
            syncBluetoothMonitoring()
            Task { await syncWeatherState() }
        }
        .alert(
            permissionGate.pendingAlert?.title ?? "",
            isPresented: permissionAlertIsPresented,
            presenting: permissionGate.pendingAlert
        ) { alert in
            Button("Cancel", role: .cancel) {
                var visibility = indicatorVisibility
                permissionGate.cancelEducation(currentVisibility: &visibility)
                indicatorVisibility = visibility
            }
            .accessibilityIdentifier("permission-education-cancel")

            Button("Continue") {
                var visibility = indicatorVisibility
                permissionGate.confirmEducation(currentVisibility: &visibility)
                indicatorVisibility = visibility
            }
            .accessibilityIdentifier("permission-education-continue")
        } message: { alert in
            Text(alert.message)
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(
                indicatorVisibility: $indicatorVisibility,
                keepScreenOn: $keepScreenOn,
                backgroundAppearance: $backgroundAppearance,
                batteryReflectiveBackground: $batteryReflectiveBackground,
                batteryDrivenScreenBrightness: $batteryDrivenScreenBrightness,
                showWiFiNetworkName: $showWiFiNetworkName,
                showStatusBar: $showStatusBar,
                showClockSeconds: $showClockSeconds,
                indicatorKinds: settingsIndicatorKinds,
                permissionGate: permissionGate
            )
        }
    }

    private var permissionAlertIsPresented: Binding<Bool> {
        Binding(
            get: { permissionGate.pendingAlert != nil },
            set: { isPresented in
                if !isPresented {
                    var visibility = indicatorVisibility
                    permissionGate.cancelEducation(currentVisibility: &visibility)
                    indicatorVisibility = visibility
                }
            }
        )
    }

    private func configurePermissionGateHandlers() {
        permissionGate.onIndicatorEnabled = { kind in
            switch kind {
            case .weather:
                Task { await weatherViewModel.refresh(requestAuthorization: true) }
            case .bluetooth:
                connectivityViewModel.updateBluetoothMonitoringEnabled(true)
            default:
                break
            }
        }
        permissionGate.onIndicatorDisabled = { kind in
            switch kind {
            case .bluetooth:
                connectivityViewModel.updateBluetoothMonitoringEnabled(false)
            default:
                break
            }
        }
    }

    private func syncBluetoothMonitoring() {
        connectivityViewModel.updateBluetoothMonitoringEnabled(isIndicatorVisible(.bluetooth))
    }

    private func syncWeatherState() async {
        guard isIndicatorVisible(.weather) else { return }

        let args = ProcessInfo.processInfo.arguments
        if args.contains("--ui-testing-weather-denied") ||
            args.contains("--ui-testing-weather-attribution") {
            await weatherViewModel.refresh(requestAuthorization: false)
            return
        }

        switch PermissionAuthorizationReader.status(for: .location) {
        case .authorized:
            await weatherViewModel.refresh(requestAuthorization: false)
        case .notDetermined:
            weatherViewModel.showNotRequestedPlaceholder()
        case .denied, .restricted, .unavailable:
            await weatherViewModel.refresh(requestAuthorization: false)
        }
    }

    @Environment(\.dashboardPalette) private var dashboardPalette

    private var dashboardBackground: Color {
        if batteryReflectiveBackground {
            let percentage = batteryViewModel.state.isDataAvailable
                ? batteryViewModel.state.percentage
                : 0
            return BatteryReflectiveBackground.backgroundColor(forPercentage: percentage)
        }
        return dashboardPalette.background
    }

    private func isIndicatorVisible(_ kind: IndicatorKind) -> Bool {
        guard kind.isFeatureEnabled else { return false }
        return indicatorVisibility[kind, default: kind.defaultVisibility]
    }

    private var doubleTapToOpenSettingsGesture: some Gesture {
        TapGesture(count: 2).onEnded {
            isSettingsPresented = true
        }
    }

    private var backgroundTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded { isSettingsPresented = true }
            .exclusively(before: TapGesture(count: 1).onEnded {
                settingsHintPresenter.requestPresentation()
            })
    }

    private var longPressHintGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5).onEnded { _ in
            settingsHintPresenter.requestPresentation()
        }
    }

    private func edgePanHintGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .local)
            .onEnded { value in
                let edgeThreshold: CGFloat = 24
                let startX = value.startLocation.x
                let isEdgeStart = startX < edgeThreshold || startX > size.width - edgeThreshold
                let dragDistance = hypot(value.translation.width, value.translation.height)
                guard isEdgeStart, dragDistance > 20 else { return }
                settingsHintPresenter.requestPresentation()
            }
    }

    @ViewBuilder
    private func tileView(
        for placeholder: IndicatorPlaceholder,
        metrics: TileMetrics,
        showsKindLabel: Bool
    ) -> some View {
        if placeholder.kind == .battery {
            BatteryIndicatorTile(
                viewModel: batteryViewModel,
                metrics: metrics,
                showsKindLabel: showsKindLabel
            )
        } else if placeholder.kind == .chargingState {
            ChargingIndicatorTile(
                viewModel: batteryViewModel,
                metrics: metrics,
                showsKindLabel: showsKindLabel
            )
        } else if placeholder.kind == .volume {
            VolumeIndicatorTile(
                volumeState: volumeViewModel.state,
                metrics: metrics,
                showsKindLabel: showsKindLabel
            )
        } else if placeholder.kind == .playback {
            PlaybackIndicatorTile(playbackState: playbackViewModel.state, metrics: metrics)
        } else if placeholder.kind == .nowPlaying {
            NowPlayingIndicatorTile(nowPlayingState: nowPlayingViewModel.state, metrics: metrics)
        } else if placeholder.kind == .wifi {
            WiFiIndicatorTile(wifiState: connectivityViewModel.state.wifi, metrics: metrics)
        } else if
            placeholder.kind == .speaker ||
            placeholder.kind == .bluetooth ||
            placeholder.kind == .ringer
        {
            ConnectivityIndicatorTile(placeholder: placeholder, metrics: metrics)
        } else if placeholder.kind == .clock {
            ClockIndicatorTile(clockState: clockViewModel.state, metrics: metrics)
        } else if placeholder.kind == .date {
            DateIndicatorTile(dateState: dateViewModel.state, metrics: metrics)
        } else {
            IndicatorTile(placeholder: placeholder, metrics: metrics)
        }
    }
}
