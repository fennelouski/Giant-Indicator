import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var weatherViewModel: WeatherViewModel
    @State private var isSettingsPresented = false
    @State private var indicatorVisibility: [IndicatorKind: Bool] = IndicatorPreferences.loadVisibility()
    @StateObject private var batteryViewModel = BatteryViewModel()
    @StateObject private var volumeViewModel = VolumeViewModel()
    @StateObject private var playbackViewModel = PlaybackViewModel()
    @StateObject private var connectivityViewModel = ConnectivityViewModel()

    private var indicators: [IndicatorPlaceholder] {
        [
            .init(kind: .battery, value: batteryViewModel.state.percentageText),
            .init(kind: .volume, value: volumeViewModel.state.percentageText),
            .init(kind: .playback, value: playbackViewModel.state.titleText),
            .init(
                kind: .wifi,
                value: connectivityViewModel.state.wifi.valueText,
                subtitle: connectivityViewModel.state.wifi.subtitleText,
                symbolOverride: connectivityViewModel.state.wifi.symbolName
            ),
            .init(
                kind: .speaker,
                value: connectivityViewModel.state.speaker.valueText,
                subtitle: connectivityViewModel.state.speaker.subtitleText,
                symbolOverride: connectivityViewModel.state.speaker.symbolName
            ),
            .init(
                kind: .bluetooth,
                value: connectivityViewModel.state.bluetooth.valueText,
                subtitle: connectivityViewModel.state.bluetooth.subtitleText,
                symbolOverride: connectivityViewModel.state.bluetooth.symbolName
            ),
            .init(
                kind: .ringer,
                value: connectivityViewModel.state.ringer.valueText,
                subtitle: connectivityViewModel.state.ringer.subtitleText,
                symbolOverride: connectivityViewModel.state.ringer.symbolName
            ),
            .fromWeatherState(weatherViewModel.displayState)
        ]
    }

    private var visibleIndicators: [IndicatorPlaceholder] {
        indicators.filter { isIndicatorVisible($0.kind) }
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
                                    tileView(for: item.placeholder)
                                        .frame(height: item.height)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .top)
                        }
                    }
                    .padding(layout.outerPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
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
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(
                indicatorVisibility: $indicatorVisibility,
                indicatorKinds: IndicatorKind.allCases
            )
        }
    }

    private func isIndicatorVisible(_ kind: IndicatorKind) -> Bool {
        indicatorVisibility[kind, default: true]
    }

    @ViewBuilder
    private func tileView(for placeholder: IndicatorPlaceholder) -> some View {
        if placeholder.kind == .battery {
            BatteryIndicatorTile(batteryState: batteryViewModel.state)
        } else if placeholder.kind == .volume {
            VolumeIndicatorTile(volumeState: volumeViewModel.state)
        } else if placeholder.kind == .playback {
            PlaybackIndicatorTile(playbackState: playbackViewModel.state)
        } else if
            placeholder.kind == .wifi ||
            placeholder.kind == .speaker ||
            placeholder.kind == .bluetooth ||
            placeholder.kind == .ringer
        {
            ConnectivityIndicatorTile(placeholder: placeholder)
        } else {
            IndicatorTile(placeholder: placeholder)
        }
    }
}

private struct MasonryLayoutPlan {
    struct Item: Identifiable {
        let placeholder: IndicatorPlaceholder
        let height: CGFloat

        var id: IndicatorKind { placeholder.kind }
    }

    struct Column {
        var items: [Item]
    }

    let columns: [Column]
    let spacing: CGFloat
    let outerPadding: CGFloat

    static func build(indicators: [IndicatorPlaceholder], in size: CGSize) -> MasonryLayoutPlan {
        let outerPadding: CGFloat = 20
        let spacing: CGFloat = 16
        let availableWidth = max(size.width - (outerPadding * 2), 1)
        let availableHeight = max(size.height - (outerPadding * 2), 1)
        let maxColumnsByWidth = max(Int((availableWidth + spacing) / (160 + spacing)), 1)
        let maxColumns = min(maxColumnsByWidth, max(indicators.count, 1))

        var bestCandidate: LayoutCandidate?
        for columnCount in 1...maxColumns {
            guard let candidate = makeCandidate(
                indicators: indicators,
                columnCount: columnCount,
                availableWidth: availableWidth,
                availableHeight: availableHeight,
                spacing: spacing
            ) else {
                continue
            }

            if let currentBest = bestCandidate {
                if candidate.score > currentBest.score {
                    bestCandidate = candidate
                }
            } else {
                bestCandidate = candidate
            }
        }

        let resolved = bestCandidate ?? fallbackCandidate(
            indicators: indicators,
            availableHeight: availableHeight,
            spacing: spacing
        )
        return MasonryLayoutPlan(columns: resolved.columns, spacing: spacing, outerPadding: outerPadding)
    }

    private struct LayoutCandidate {
        let columns: [Column]
        let score: CGFloat
    }

    private static func makeCandidate(
        indicators: [IndicatorPlaceholder],
        columnCount: Int,
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        spacing: CGFloat
    ) -> LayoutCandidate? {
        guard columnCount > 0 else { return nil }

        let tileWidth = (availableWidth - (spacing * CGFloat(columnCount - 1))) / CGFloat(columnCount)
        guard tileWidth >= 140 else { return nil }

        var columnHeights = Array(repeating: CGFloat(0), count: columnCount)
        var columns = Array(repeating: [IndicatorPlaceholder](), count: columnCount)

        for indicator in indicators {
            let target = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            let baseHeight = preferredTileHeight(for: indicator.kind)
            if !columns[target].isEmpty {
                columnHeights[target] += spacing
            }
            columnHeights[target] += baseHeight
            columns[target].append(indicator)
        }

        let maxColumnHeight = columnHeights.max() ?? 1
        let scale = min(max(availableHeight / maxColumnHeight, 0.52), 1.0)
        let minimumHeight: CGFloat = 130

        let builtColumns = columns.map { column in
            Column(
                items: column.map { placeholder in
                    let scaledHeight = preferredTileHeight(for: placeholder.kind) * scale
                    return Item(
                        placeholder: placeholder,
                        height: max(minimumHeight, scaledHeight)
                    )
                }
            )
        }

        let score = (scale * 10_000) + tileWidth
        return LayoutCandidate(columns: builtColumns, score: score)
    }

    private static func fallbackCandidate(
        indicators: [IndicatorPlaceholder],
        availableHeight: CGFloat,
        spacing: CGFloat
    ) -> LayoutCandidate {
        let count = max(indicators.count, 1)
        let totalSpacing = spacing * CGFloat(max(count - 1, 0))
        let height = max((availableHeight - totalSpacing) / CGFloat(count), 130)
        let column = Column(
            items: indicators.map { Item(placeholder: $0, height: height) }
        )
        return LayoutCandidate(columns: [column], score: 0)
    }

    private static func preferredTileHeight(for kind: IndicatorKind) -> CGFloat {
        switch kind {
        case .weather:
            return 300
        case .battery:
            return 250
        case .volume:
            return 250
        case .playback:
            return 250
        case .wifi, .speaker, .bluetooth, .ringer:
            return 220
        }
    }
}

private struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var indicatorVisibility: [IndicatorKind: Bool]
    let indicatorKinds: [IndicatorKind]

    var body: some View {
        NavigationStack {
            List {
                Section("Visible Indicators") {
                    ForEach(indicatorKinds) { kind in
                        Toggle(isOn: binding(for: kind)) {
                            Label(kind.displayName, systemImage: kind.symbol)
                        }
                        .accessibilityIdentifier("indicator-toggle-\(kind.rawValue)")
                    }
                }
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

    private func binding(for kind: IndicatorKind) -> Binding<Bool> {
        Binding(
            get: { indicatorVisibility[kind, default: true] },
            set: { newValue in
                indicatorVisibility[kind] = newValue
                IndicatorPreferences.setVisibility(newValue, for: kind)
            }
        )
    }
}

enum IndicatorKind: String, CaseIterable, Identifiable {
    case weather
    case battery
    case volume
    case playback
    case wifi
    case speaker
    case bluetooth
    case ringer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weather:
            return "Weather"
        case .battery:
            return "Battery"
        case .volume:
            return "Volume"
        case .playback:
            return "Playback"
        case .wifi:
            return "Wi-Fi"
        case .speaker:
            return "Speaker/Output"
        case .bluetooth:
            return "Bluetooth"
        case .ringer:
            return "Ringer/Silent"
        }
    }

    var symbol: String {
        switch self {
        case .weather:
            return "cloud.sun.fill"
        case .battery:
            return "battery.75"
        case .volume:
            return "speaker.wave.2.fill"
        case .playback:
            return "play.fill"
        case .wifi:
            return "wifi"
        case .speaker:
            return "hifispeaker.fill"
        case .bluetooth:
            return "dot.radiowaves.left.and.right"
        case .ringer:
            return "bell.fill"
        }
    }

    static var defaultVisibilityState: [IndicatorKind: Bool] {
        Dictionary(uniqueKeysWithValues: allCases.map { ($0, true) })
    }

    var visibilityStorageKey: String {
        "indicator.visibility.\(rawValue)"
    }
}

private struct IndicatorPlaceholder: Identifiable {
    let kind: IndicatorKind
    let value: String
    var subtitle: String?
    var attribution: WeatherAttributionData?
    var symbolOverride: String? = nil

    var id: IndicatorKind { kind }
    var title: String { kind.displayName }
    var symbol: String { symbolOverride ?? kind.symbol }

    static func fromWeatherState(_ state: WeatherDisplayState) -> IndicatorPlaceholder {
        guard let snapshot = state.snapshot else {
            let subtitle: String
            switch state.permissionState {
            case .denied:
                subtitle = "Location access is off"
            case .restricted:
                subtitle = "Location access is restricted"
            case .unavailable:
                subtitle = "Location currently unavailable"
            case .authorized, .none:
                subtitle = "Current Location"
            }

            return IndicatorPlaceholder(
                kind: .weather,
                value: state.errorMessage ?? "Loading…",
                subtitle: subtitle,
                attribution: nil
            )
        }

        let measurement = Measurement(value: snapshot.temperatureCelsius, unit: UnitTemperature.celsius)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .short
        let value = formatter.string(from: measurement)

        var subtitle = snapshot.conditionDescription
        if let source = state.source {
            let sourceText = source == .fresh ? "Fresh" : "Cached"
            subtitle = "\(subtitle) · \(sourceText)"
        }

        return IndicatorPlaceholder(
            kind: .weather,
            value: value,
            subtitle: subtitle,
            attribution: state.attribution
        )
    }
}

enum IndicatorPreferences {
    static let defaults = UserDefaults.standard

    static var allVisibilityKeys: [String] {
        IndicatorKind.allCases.map(\.visibilityStorageKey)
    }

    static func loadVisibility() -> [IndicatorKind: Bool] {
        var visibility = IndicatorKind.defaultVisibilityState

        for kind in IndicatorKind.allCases {
            let key = kind.visibilityStorageKey
            if defaults.object(forKey: key) != nil {
                visibility[kind] = defaults.bool(forKey: key)
            }
        }

        return visibility
    }

    static func setVisibility(_ isVisible: Bool, for kind: IndicatorKind) {
        defaults.set(isVisible, forKey: kind.visibilityStorageKey)
    }

    static func resetVisibility() {
        allVisibilityKeys.forEach(defaults.removeObject(forKey:))
    }
}

private struct EmptyIndicatorsView: View {
    let openSettings: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 60, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))

            Text("No indicators enabled")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Open Settings to choose indicators.")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)

            Button("Open Settings") {
                openSettings()
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.2))
            .foregroundStyle(.white)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct IndicatorTile: View {
    let placeholder: IndicatorPlaceholder

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: placeholder.symbol)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(.white)

            Text(placeholder.value)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityIdentifier("\(placeholder.kind.rawValue)-value-label")

            Text(placeholder.title)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let subtitle = placeholder.subtitle {
                Text(subtitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("\(placeholder.kind.rawValue)-subtitle-label")
            }

            if let attribution = placeholder.attribution {
                WeatherAttributionView(attribution: attribution)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .accessibilityIdentifier("indicator-tile-\(placeholder.kind.rawValue)")
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct ConnectivityIndicatorTile: View {
    let placeholder: IndicatorPlaceholder

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: placeholder.symbol)
                .font(.system(size: 68, weight: .bold))
                .foregroundStyle(.white)
                .frame(height: 82)
                .padding(.horizontal, 8)
                .accessibilityHidden(true)

            Text(placeholder.value)
                .font(.system(size: 46, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityIdentifier("\(placeholder.kind.rawValue)-value-label")

            Text(placeholder.title)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)

            if let subtitle = placeholder.subtitle {
                Text(subtitle)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("\(placeholder.kind.rawValue)-subtitle-label")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .accessibilityIdentifier("indicator-tile-\(placeholder.kind.rawValue)")
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct BatteryIndicatorTile: View {
    let batteryState: BatteryState

    var body: some View {
        VStack(spacing: 20) {
            BatteryIcon(level: batteryState.normalizedLevel)
                .frame(height: 82)
                .padding(.horizontal, 8)

            if batteryState.isAvailable {
                Text(batteryState.percentageText)
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .accessibilityIdentifier("battery-percentage-label")
            } else {
                Text("--")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("battery-percentage-label")

                Text(batteryState.unavailableReason)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("battery-unavailable-label")
            }

            Text("Battery")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .accessibilityIdentifier("indicator-tile-battery")
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct BatteryIcon: View {
    let level: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let capWidth = max(12, proxy.size.width * 0.05)
            let shellWidth = max(16, proxy.size.width - capWidth - 10)
            let strokeWidth: CGFloat = 4
            let contentPadding = strokeWidth + 5
            let contentWidth = max(0, shellWidth - contentPadding * 2)
            let clampedLevel = min(max(level, 0), 1)

            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white, lineWidth: strokeWidth)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white)
                            .frame(width: contentWidth * clampedLevel)
                            .padding(contentPadding)
                            .accessibilityHidden(true)
                    }
                    .frame(width: shellWidth)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white)
                    .frame(width: capWidth, height: max(18, proxy.size.height * 0.42))
            }
        }
    }
}

private struct VolumeIndicatorTile: View {
    let volumeState: VolumeState

    var body: some View {
        VStack(spacing: 20) {
            VolumeIcon(level: volumeState.normalizedLevel, symbolName: volumeState.symbolName)
                .frame(height: 82)
                .padding(.horizontal, 8)

            if volumeState.isAvailable {
                Text(volumeState.percentageText)
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .accessibilityIdentifier("volume-percentage-label")
            } else {
                Text("--")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("volume-percentage-label")

                Text(volumeState.unavailableReason)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("volume-unavailable-label")
            }

            Text("Volume")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .accessibilityIdentifier("indicator-tile-volume")
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct PlaybackIndicatorTile: View {
    let playbackState: PlaybackState

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: playbackState.symbolName)
                .font(.system(size: 68, weight: .bold))
                .foregroundStyle(.white)
                .frame(height: 82)
                .padding(.horizontal, 8)
                .accessibilityHidden(true)

            Text(playbackState.titleText)
                .font(.system(size: 52, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityIdentifier("playback-state-label")

            Text("Playback")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)

            Text(playbackState.subtitleText)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier("playback-subtitle-label")
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .accessibilityIdentifier("indicator-tile-playback")
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct VolumeIcon: View {
    let level: CGFloat
    let symbolName: String

    var body: some View {
        GeometryReader { proxy in
            let iconAreaWidth = proxy.size.width * 0.34
            let barAreaWidth = max(0, proxy.size.width - iconAreaWidth - 16)
            let clampedLevel = min(max(level, 0), 1)
            let barHeight = max(18, proxy.size.height * 0.28)

            HStack(spacing: 16) {
                Image(systemName: symbolName)
                    .font(.system(size: max(26, proxy.size.height * 0.5), weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: iconAreaWidth, alignment: .leading)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
                        .fill(Color.white.opacity(0.18))

                    RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
                        .fill(Color.white)
                        .frame(width: barAreaWidth * clampedLevel)
                }
                .frame(width: barAreaWidth, height: barHeight)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("Dashboard") {
    ContentView()
        .environmentObject(WeatherViewModel())
}

#Preview("Compact Dashboard", traits: .fixedLayout(width: 350, height: 750)) {
    ContentView()
        .environmentObject(WeatherViewModel())
}
