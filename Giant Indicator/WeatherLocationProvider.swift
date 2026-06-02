import CoreLocation
import Foundation

final class WeatherLocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Never>?
    private let fallbackLocation = CLLocation(latitude: 37.3349, longitude: -122.0090)

    func resolveLocation() async -> CLLocation {
        if let location = manager.location {
            return location
        }

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer

        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }

        manager.requestLocation()

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last ?? fallbackLocation
        continuation?.resume(returning: location)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(returning: fallbackLocation)
        continuation = nil
    }
}
