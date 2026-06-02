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
