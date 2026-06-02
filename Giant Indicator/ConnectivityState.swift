import Foundation

enum ConnectivityAvailability: Equatable {
    case available
    case unavailable(reason: String)
}

struct ConnectivityIndicatorState: Equatable {
    let title: String
    let valueText: String
    let subtitleText: String
    let symbolName: String
    let availability: ConnectivityAvailability

    static func unavailable(
        title: String,
        subtitle: String,
        symbolName: String,
        reason: String = "Unavailable"
    ) -> ConnectivityIndicatorState {
        ConnectivityIndicatorState(
            title: title,
            valueText: "--",
            subtitleText: subtitle,
            symbolName: symbolName,
            availability: .unavailable(reason: reason)
        )
    }
}

struct ConnectivityState: Equatable {
    let wifi: ConnectivityIndicatorState
    let speaker: ConnectivityIndicatorState
    let bluetooth: ConnectivityIndicatorState
    let ringer: ConnectivityIndicatorState

    static let unavailable = ConnectivityState(
        wifi: .unavailable(title: "Wi-Fi", subtitle: "Status unavailable", symbolName: "wifi.slash"),
        speaker: .unavailable(title: "Speaker/Output", subtitle: "Output unavailable", symbolName: "hifispeaker.slash"),
        bluetooth: .unavailable(title: "Bluetooth", subtitle: "Status unavailable", symbolName: "bolt.horizontal"),
        ringer: .unavailable(title: "Ringer/Silent", subtitle: "Status unavailable", symbolName: "bell.slash")
    )
}
