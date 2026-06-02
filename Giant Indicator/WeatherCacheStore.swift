import Foundation

struct WeatherCacheStore {
    private struct CacheEnvelope: Codable {
        let snapshot: WeatherSnapshot
        let attribution: WeatherAttributionData
        let lastFetchAt: Date
    }

    private let defaults: UserDefaults
    private let key = "weather.cache.envelope"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> (snapshot: WeatherSnapshot, attribution: WeatherAttributionData, lastFetchAt: Date)? {
        guard let data = defaults.data(forKey: key) else { return nil }
        guard let envelope = try? JSONDecoder().decode(CacheEnvelope.self, from: data) else { return nil }
        return (envelope.snapshot, envelope.attribution, envelope.lastFetchAt)
    }

    func save(snapshot: WeatherSnapshot, attribution: WeatherAttributionData, lastFetchAt: Date = Date()) {
        let envelope = CacheEnvelope(snapshot: snapshot, attribution: attribution, lastFetchAt: lastFetchAt)
        guard let encoded = try? JSONEncoder().encode(envelope) else { return }
        defaults.set(encoded, forKey: key)
    }
}
