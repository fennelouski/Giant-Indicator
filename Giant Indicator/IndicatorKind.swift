//
//  IndicatorKind.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import Foundation

enum SettingsGroup: String, CaseIterable {
    case battery
    case wifi
    case timeAndDate
    case media
    case connectivity
    case weather
}

enum IndicatorKind: String, CaseIterable, Identifiable {
    case weather
    case battery
    case chargingState
    case volume
    case playback
    case nowPlaying
    case wifi
    case speaker
    case bluetooth
    case ringer
    case clock
    case date

    var id: String { rawValue }

    enum PlatformCapabilityHandling: Equatable {
        case supported
        case showUnavailableState(reason: String)
        case hidden
    }

    var displayName: String {
        switch self {
        case .weather:
            return "Weather"
        case .battery:
            return "Battery"
        case .chargingState:
            return "Charging State"
        case .volume:
            return "Volume"
        case .playback:
            return "Playback"
        case .nowPlaying:
            return "Now Playing"
        case .wifi:
            return "Wi-Fi"
        case .speaker:
            return "Speaker/Output"
        case .bluetooth:
            return "Bluetooth"
        case .ringer:
            return "Ringer/Silent"
        case .clock:
            return "Time"
        case .date:
            return "Date"
        }
    }

    var symbol: String {
        switch self {
        case .weather:
            return "cloud.sun.fill"
        case .battery:
            return "battery.75"
        case .chargingState:
            return "bolt.batteryblock.fill"
        case .volume:
            return "speaker.wave.2.fill"
        case .playback:
            return "play.fill"
        case .nowPlaying:
            return "music.note"
        case .wifi:
            return "wifi"
        case .speaker:
            return "hifispeaker.fill"
        case .bluetooth:
            return "dot.radiowaves.left.and.right"
        case .ringer:
            return "bell.fill"
        case .clock:
            return "clock.fill"
        case .date:
            return "calendar"
        }
    }

    /// When `false`, the indicator stays out of the dashboard and settings; tile UI remains for a future fix.
    var isFeatureEnabled: Bool {
        switch self {
        case .bluetooth:
            return false
        default:
            return true
        }
    }

    /// Default dashboard indicators for fresh installs — giant battery plus charging state.
    static var defaultDashboardFavorites: Set<IndicatorKind> {
        [.battery, .chargingState]
    }

    var defaultVisibility: Bool {
        isFeatureEnabled &&
            platformCapabilityHandling != .hidden &&
            Self.defaultDashboardFavorites.contains(self)
    }

    static var defaultVisibilityState: [IndicatorKind: Bool] {
        Dictionary(
            uniqueKeysWithValues: allCases.map { kind in
                (kind, kind.defaultVisibility)
            }
        )
    }

    var visibilityStorageKey: String {
        "indicator.visibility.\(rawValue)"
    }

    var platformCapabilityHandling: PlatformCapabilityHandling {
        switch self {
        case .ringer:
            #if canImport(UIKit)
            return .showUnavailableState(reason: "iOS does not expose ringer switch state")
            #else
            return .hidden
            #endif
        case .speaker:
            #if canImport(AVFoundation) && canImport(UIKit)
            return .supported
            #else
            return .hidden
            #endif
        default:
            return .supported
        }
    }

    var isVisibleInSettings: Bool {
        isFeatureEnabled && platformCapabilityHandling != .hidden
    }

    var settingsGroup: SettingsGroup {
        switch self {
        case .battery, .chargingState:
            return .battery
        case .wifi:
            return .wifi
        case .clock, .date:
            return .timeAndDate
        case .volume, .playback, .nowPlaying:
            return .media
        case .speaker, .bluetooth, .ringer:
            return .connectivity
        case .weather:
            return .weather
        }
    }

    static func visibleInSettings(for group: SettingsGroup) -> [IndicatorKind] {
        allCases.filter { $0.settingsGroup == group && $0.isVisibleInSettings }
    }
}
