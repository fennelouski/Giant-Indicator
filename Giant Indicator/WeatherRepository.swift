import CoreLocation
import Foundation
import WeatherKit

protocol WeatherServiceClient {
    func weather(for location: CLLocation) async throws -> Weather
    func attribution() async throws -> WeatherAttribution
}

struct LiveWeatherServiceClient: WeatherServiceClient {
    func weather(for location: CLLocation) async throws -> Weather {
        try await WeatherService.shared.weather(for: location)
    }

    func attribution() async throws -> WeatherAttribution {
        try await WeatherService.shared.attribution
    }
}

actor WeatherRepository {
    private let service: WeatherServiceClient
    private let cacheStore: WeatherCacheStore
    private let now: () -> Date

    init(
        service: WeatherServiceClient = LiveWeatherServiceClient(),
        cacheStore: WeatherCacheStore = WeatherCacheStore(),
        now: @escaping () -> Date = Date.init
    ) {
        self.service = service
        self.cacheStore = cacheStore
        self.now = now
    }

    func loadWeather(location: CLLocation) async -> WeatherDisplayState {
        let currentDate = now()
        let cached = cacheStore.load()

        if
            let cached,
            !WeatherCachePolicy.shouldRefresh(lastFetchAt: cached.lastFetchAt, now: currentDate)
        {
            return WeatherDisplayState(
                snapshot: hydratedSnapshot(cached.snapshot, at: currentDate),
                attribution: cached.attribution,
                source: .cached,
                errorMessage: nil
            )
        }

        do {
            let weather = try await service.weather(for: location)
            let attribution = try await service.attribution()
            let snapshot = makeSnapshot(from: weather, fetchedAt: currentDate)
            let attributionData = makeAttribution(from: attribution)
            cacheStore.save(snapshot: snapshot, attribution: attributionData, lastFetchAt: currentDate)

            return WeatherDisplayState(
                snapshot: snapshot,
                attribution: attributionData,
                source: .fresh,
                errorMessage: nil
            )
        } catch {
            if let cached {
                return WeatherDisplayState(
                    snapshot: hydratedSnapshot(cached.snapshot, at: currentDate),
                    attribution: cached.attribution,
                    source: .cached,
                    errorMessage: "Using cached weather."
                )
            }

            return WeatherDisplayState(
                snapshot: nil,
                attribution: nil,
                source: nil,
                errorMessage: "Weather unavailable."
            )
        }
    }

    private func hydratedSnapshot(_ snapshot: WeatherSnapshot, at date: Date) -> WeatherSnapshot {
        guard let nearest = WeatherCachePolicy.nearestHourlyPoint(from: snapshot.hourly, to: date) else {
            return snapshot
        }

        return WeatherSnapshot(
            locationName: snapshot.locationName,
            conditionDescription: snapshot.conditionDescription,
            symbolName: nearest.symbolName,
            temperatureCelsius: nearest.temperatureCelsius,
            fetchedAt: snapshot.fetchedAt,
            hourly: snapshot.hourly
        )
    }

    private func makeSnapshot(from weather: Weather, fetchedAt: Date) -> WeatherSnapshot {
        let hourly: [HourlyForecastPoint] = weather.hourlyForecast.forecast.map { hour in
            HourlyForecastPoint(
                date: hour.date,
                temperatureCelsius: hour.temperature.converted(to: .celsius).value,
                symbolName: hour.symbolName
            )
        }

        return WeatherSnapshot(
            locationName: "Current Location",
            conditionDescription: weather.currentWeather.condition.description,
            symbolName: weather.currentWeather.symbolName,
            temperatureCelsius: weather.currentWeather.temperature.converted(to: .celsius).value,
            fetchedAt: fetchedAt,
            hourly: hourly
        )
    }

    private func makeAttribution(from attribution: WeatherAttribution) -> WeatherAttributionData {
        WeatherAttributionData(
            combinedMarkDarkURL: attribution.combinedMarkDarkURL,
            combinedMarkLightURL: attribution.combinedMarkLightURL,
            squareMarkURL: attribution.squareMarkURL,
            legalPageURL: attribution.legalPageURL,
            legalAttributionText: attribution.legalAttributionText
        )
    }
}
