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
        let location = await locationProvider.resolveLocation()
        displayState = await repository.loadWeather(location: location)
    }
}
