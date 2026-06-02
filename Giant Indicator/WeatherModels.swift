import Foundation

struct WeatherSnapshot: Codable, Equatable {
    let locationName: String
    let conditionDescription: String
    let symbolName: String
    let temperatureCelsius: Double
    let fetchedAt: Date
    let hourly: [HourlyForecastPoint]
}

struct HourlyForecastPoint: Codable, Equatable {
    let date: Date
    let temperatureCelsius: Double
    let symbolName: String
}

struct WeatherAttributionData: Codable, Equatable {
    let combinedMarkDarkURL: URL?
    let combinedMarkLightURL: URL?
    let squareMarkURL: URL?
    let legalPageURL: URL?
    let legalAttributionText: String?
}

enum WeatherDataSource: Equatable {
    case fresh
    case cached
}

struct WeatherDisplayState: Equatable {
    var snapshot: WeatherSnapshot?
    var attribution: WeatherAttributionData?
    var source: WeatherDataSource?
    var errorMessage: String?

    static let empty = WeatherDisplayState(
        snapshot: nil,
        attribution: nil,
        source: nil,
        errorMessage: nil
    )
}
