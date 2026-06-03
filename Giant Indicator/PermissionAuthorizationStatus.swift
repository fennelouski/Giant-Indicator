//
//  PermissionAuthorizationStatus.swift
//  Giant Indicator
//

import CoreLocation
import Foundation

#if canImport(CoreBluetooth)
import CoreBluetooth
#endif

enum PermissionAuthorizationStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
    case unavailable
}

enum PermissionAuthorizationReader {
    static func status(for kind: PermissionKind) -> PermissionAuthorizationStatus {
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-force-permission-not-determined") {
            switch kind {
            case .location, .bluetooth:
                return .notDetermined
            }
        }

        switch kind {
        case .location:
            return locationStatus()
        case .bluetooth:
            return bluetoothStatus()
        }
    }

    private static func locationStatus() -> PermissionAuthorizationStatus {
        let manager = CLLocationManager()
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .unavailable
        }
    }

    private static func bluetoothStatus() -> PermissionAuthorizationStatus {
        #if canImport(CoreBluetooth)
        switch CBCentralManager.authorization {
        case .allowedAlways:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .unavailable
        }
        #else
        return .unavailable
        #endif
    }
}
