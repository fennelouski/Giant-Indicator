//
//  PermissionKind.swift
//  Giant Indicator
//

import Foundation

enum PermissionKind: String, CaseIterable {
    case location
    case bluetooth

    var educationTitle: String {
        switch self {
        case .location:
            return "Location Access"
        case .bluetooth:
            return "Bluetooth Access"
        }
    }

    var educationMessage: String {
        switch self {
        case .location:
            return "Local weather needs your location. You can change this anytime in Settings."
        case .bluetooth:
            return "The Bluetooth indicator needs Bluetooth access to show whether Bluetooth is on or off."
        }
    }

    static func required(for kind: IndicatorKind) -> Set<PermissionKind> {
        switch kind {
        case .weather:
            return [.location]
        case .bluetooth:
            return [.bluetooth]
        default:
            return []
        }
    }

    static func requiredForEnabling(showWiFiNetworkName: Bool) -> Set<PermissionKind> {
        _ = showWiFiNetworkName
        return []
    }
}
