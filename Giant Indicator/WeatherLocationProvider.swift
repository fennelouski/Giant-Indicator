import CoreLocation
import Foundation

enum WeatherLocationResolution: Equatable {
    case authorized(CLLocation)
    case denied
    case restricted
    case unavailable
}

final class WeatherLocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<WeatherLocationResolution, Never>?

    func resolveLocation() async -> WeatherLocationResolution {
        if let location = manager.location {
            return .authorized(location)
        }

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .unavailable
        }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            continuation?.resume(returning: .authorized(location))
        } else {
            continuation?.resume(returning: .unavailable)
        }
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(returning: .unavailable)
        continuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied:
            continuation?.resume(returning: .denied)
            continuation = nil
        case .restricted:
            continuation?.resume(returning: .restricted)
            continuation = nil
        case .notDetermined:
            break
        @unknown default:
            continuation?.resume(returning: .unavailable)
            continuation = nil
        }
    }

    func permissionState(from resolution: WeatherLocationResolution) -> WeatherPermissionState {
        switch resolution {
        case .authorized:
            return .authorized
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

    func resolveWeatherLocation() async -> (location: CLLocation?, permission: WeatherPermissionState, message: String?) {
        let initialResolution = await resolveLocation()
        let resolved = resolvedLocationWithTestingSupport(initialResolution)
        return (
            location: location(from: resolved),
            permission: permissionState(from: resolved),
            message: userVisibleErrorMessage(resolved)
        )
    }
}
