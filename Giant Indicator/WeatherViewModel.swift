import Foundation
import Combine

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published private(set) var displayState: WeatherDisplayState = .empty

    private let repository: WeatherRepository
    private let locationProvider: WeatherLocationProvider

    init(
        repository: WeatherRepository = WeatherRepository(
            service: LiveWeatherServiceClient(),
            cacheStore: WeatherCacheStore()
        ),
        locationProvider: WeatherLocationProvider = WeatherLocationProvider()
    ) {
        self.repository = repository
        self.locationProvider = locationProvider
    }

    func refreshOnLaunch() async {
        if let uiTestingState = uiTestingDisplayState() {
            displayState = uiTestingState
            return
        }

        let resolved = await locationProvider.resolveWeatherLocation()
        guard let location = resolved.location else {
            displayState = WeatherDisplayState(
                snapshot: nil,
                attribution: nil,
                source: nil,
                errorMessage: resolved.message ?? "Weather unavailable.",
                permissionState: resolved.permission
            )
            return
        }

        var repositoryState = await repository.loadWeather(location: location)
        repositoryState.permissionState = resolved.permission
        if repositoryState.errorMessage == nil {
            repositoryState.errorMessage = resolved.message
        }
        displayState = repositoryState
    }

    private func uiTestingDisplayState() -> WeatherDisplayState? {
        let args = ProcessInfo.processInfo.arguments

        if args.contains("--ui-testing-weather-denied") {
            return WeatherDisplayState(
                snapshot: nil,
                attribution: nil,
                source: nil,
                errorMessage: "Location access is off. Turn on Location Services in Settings to see local weather.",
                permissionState: .denied
            )
        }

        if args.contains("--ui-testing-weather-attribution") {
            let snapshot = WeatherSnapshot(
                locationName: "Current Location",
                conditionDescription: "Partly Cloudy",
                symbolName: "cloud.sun.fill",
                temperatureCelsius: 21,
                fetchedAt: Date(timeIntervalSince1970: 1_000),
                hourly: []
            )
            let attribution = WeatherAttributionData(
                combinedMarkDarkURL: nil,
                combinedMarkLightURL: nil,
                squareMarkURL: nil,
                legalPageURL: URL(string: "https://weather-data.apple.com/legal-attribution.html"),
                legalAttributionText: "Weather data is provided by Apple Weather."
            )

            return WeatherDisplayState(
                snapshot: snapshot,
                attribution: attribution,
                source: .fresh,
                errorMessage: nil,
                permissionState: .authorized
            )
        }

        return nil
    }
}
