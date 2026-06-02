//
//  IndicatorKind.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import Foundation

enum IndicatorKind: String, CaseIterable, Identifiable {
    case weather
    case battery
    case volume
    case playback
    case nowPlaying
    case wifi
    case speaker
    case bluetooth
    case ringer

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
        }
    }

    static var defaultVisibilityState: [IndicatorKind: Bool] {
        Dictionary(
            uniqueKeysWithValues: allCases.map { kind in
                (kind, kind.platformCapabilityHandling != .hidden)
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
        platformCapabilityHandling != .hidden
    }
}
