import Foundation

enum WeatherCachePolicy {
    static let refreshInterval: TimeInterval = 60 * 60 * 3

    static func shouldRefresh(lastFetchAt: Date?, now: Date = Date()) -> Bool {
        guard let lastFetchAt else { return true }
        return now.timeIntervalSince(lastFetchAt) >= refreshInterval
    }

    static func nearestHourlyPoint(
        from hourly: [HourlyForecastPoint],
        to targetDate: Date
    ) -> HourlyForecastPoint? {
        hourly.min { lhs, rhs in
            abs(lhs.date.timeIntervalSince(targetDate)) < abs(rhs.date.timeIntervalSince(targetDate))
        }
    }
}
