import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var weatherViewModel: WeatherViewModel
    @State private var isSettingsPresented = false
    @State private var indicatorVisibility: [IndicatorKind: Bool] = IndicatorPreferences.loadVisibility()
    @State private var keepScreenOn = DisplayPreferences.keepScreenOn
    @StateObject private var batteryViewModel = BatteryViewModel()
    @StateObject private var volumeViewModel = VolumeViewModel()
    @StateObject private var playbackViewModel = PlaybackViewModel()
    @StateObject private var nowPlayingViewModel = NowPlayingViewModel()
    @StateObject private var connectivityViewModel = ConnectivityViewModel()

    private var indicators: [IndicatorPlaceholder] {
        [
            IndicatorPlaceholder(kind: .battery, value: batteryViewModel.state.percentageText),
            IndicatorPlaceholder(kind: .volume, value: volumeViewModel.state.percentageText),
            IndicatorPlaceholder(kind: .playback, value: playbackViewModel.state.titleText),
            IndicatorPlaceholder(kind: .nowPlaying, value: nowPlayingViewModel.state.titleText),
            IndicatorPlaceholder.fromConnectivityIndicator(
                connectivityViewModel.state.wifi,
                kind: .wifi
            ),
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
            IndicatorPlaceholder.fromWeatherState(weatherViewModel.displayState)
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
        ZStack {
            Color.black
                .ignoresSafeArea()

            if visibleIndicators.isEmpty {
                EmptyIndicatorsView {
                    isSettingsPresented = true
                }
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
                                    tileView(for: item.placeholder, metrics: metrics)
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
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear
                .frame(height: 56)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                isSettingsPresented = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.12), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
            .padding(.trailing, 16)
            .accessibilityLabel("Open Settings")
            .accessibilityIdentifier("open-settings-button")
        }
        .keepScreenAwake(keepScreenOn)
        .onChange(of: keepScreenOn) { _, newValue in
            DisplayPreferences.keepScreenOn = newValue
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(
                indicatorVisibility: $indicatorVisibility,
                keepScreenOn: $keepScreenOn,
                indicatorKinds: settingsIndicatorKinds
            )
        }
    }

    private func isIndicatorVisible(_ kind: IndicatorKind) -> Bool {
        indicatorVisibility[kind, default: true]
    }

    @ViewBuilder
    private func tileView(for placeholder: IndicatorPlaceholder, metrics: TileMetrics) -> some View {
        if placeholder.kind == .battery {
            BatteryIndicatorTile(batteryState: batteryViewModel.state, metrics: metrics)
        } else if placeholder.kind == .volume {
            VolumeIndicatorTile(volumeState: volumeViewModel.state, metrics: metrics)
        } else if placeholder.kind == .playback {
            PlaybackIndicatorTile(playbackState: playbackViewModel.state, metrics: metrics)
        } else if placeholder.kind == .nowPlaying {
            NowPlayingIndicatorTile(nowPlayingState: nowPlayingViewModel.state, metrics: metrics)
        } else if
            placeholder.kind == .wifi ||
            placeholder.kind == .speaker ||
            placeholder.kind == .bluetooth ||
            placeholder.kind == .ringer
        {
            ConnectivityIndicatorTile(placeholder: placeholder, metrics: metrics)
        } else {
            IndicatorTile(placeholder: placeholder, metrics: metrics)
        }
    }
}
