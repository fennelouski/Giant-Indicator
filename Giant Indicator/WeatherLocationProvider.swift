import CoreLocation
import Foundation

enum WeatherLocationResolution: Equatable {
    case authorized(CLLocation)
    case notDetermined
    case denied
    case restricted
    case unavailable
}

@MainActor
final class WeatherLocationRequest {
    private var readers: [CheckedContinuation<WeatherLocationResolution, Never>] = []

    func add(_ reader: CheckedContinuation<WeatherLocationResolution, Never>) -> Bool {
        let shouldStart = readers.isEmpty
        readers.append(reader)
        return shouldStart
    }

    func complete(_ resolution: WeatherLocationResolution) {
        let pending = readers
        readers.removeAll()
        for reader in pending { reader.resume(returning: resolution) }
    }
}

final class WeatherLocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let pendingRequest = WeatherLocationRequest()

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    func requestWhenInUseAccess() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.requestWhenInUseAuthorization()
    }

    func resolveLocation(requestAuthorization: Bool) async -> WeatherLocationResolution {
        if let location = manager.location {
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                return .authorized(location)
            default:
                break
            }
        }

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            break
        case .notDetermined:
            guard requestAuthorization else { return .notDetermined }
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .unavailable
        }

        return await withCheckedContinuation { continuation in
            guard pendingRequest.add(continuation) else { return }
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                manager.requestLocation()
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .denied:
                pendingRequest.complete(.denied)
            case .restricted:
                pendingRequest.complete(.restricted)
            @unknown default:
                pendingRequest.complete(.unavailable)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            pendingRequest.complete(.authorized(location))
        } else {
            pendingRequest.complete(.unavailable)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        pendingRequest.complete(.unavailable)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied:
            pendingRequest.complete(.denied)
        case .restricted:
            pendingRequest.complete(.restricted)
        case .notDetermined:
            break
        @unknown default:
            pendingRequest.complete(.unavailable)
        }
    }

    func permissionState(from resolution: WeatherLocationResolution) -> WeatherPermissionState {
        switch resolution {
        case .authorized:
            return .authorized
        case .notDetermined:
            return .notRequested
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .unavailable:
            return .unavailable
        }
    }

    private func location(from resolution: WeatherLocationResolution) -> CLLocation? {
        guard case .authorized(let location) = resolution else { return nil }
        return location
    }

    private func message(for resolution: WeatherLocationResolution) -> String {
        switch resolution {
        case .authorized:
            return ""
        case .notDetermined:
            return ""
        case .denied:
            return "Location access is off. Turn on Location Services in Settings to see local weather."
        case .restricted:
            return "Location access is restricted on this device."
        case .unavailable:
            return "Unable to determine your location right now."
        }
    }

    private func resolveWithFallbackForUITesting() -> WeatherLocationResolution {
        let fallbackLocation = CLLocation(latitude: 37.3349, longitude: -122.0090)
        return .authorized(fallbackLocation)
    }

    private func shouldUseUITestingFallback() -> Bool {
        ProcessInfo.processInfo.arguments.contains("--ui-testing-weather-fallback-location")
    }

    private func resolvedLocationWithTestingSupport(_ resolution: WeatherLocationResolution) -> WeatherLocationResolution {
        if shouldUseUITestingFallback(), case .unavailable = resolution {
            return resolveWithFallbackForUITesting()
        }
        return resolution
    }

    func userVisibleErrorMessage(_ resolution: WeatherLocationResolution) -> String? {
        let value = message(for: resolution)
        return value.isEmpty ? nil : value
    }

    func resolveWeatherLocation(requestAuthorization: Bool) async -> (
        location: CLLocation?,
        permission: WeatherPermissionState,
        message: String?
    ) {
        let initialResolution = await resolveLocation(requestAuthorization: requestAuthorization)
        let resolved = resolvedLocationWithTestingSupport(initialResolution)
        return (
            location: location(from: resolved),
            permission: permissionState(from: resolved),
            message: userVisibleErrorMessage(resolved)
        )
    }
}
