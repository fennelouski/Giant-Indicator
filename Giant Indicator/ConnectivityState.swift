import Foundation

enum ConnectivityAvailability: Equatable {
    case available
    case unavailable(reason: String)
}

struct ConnectivityIndicatorState: Equatable, IndicatorUnavailablePresenting {
    let title: String
    let valueText: String
    let subtitleText: String
    let symbolName: String
    let availability: ConnectivityAvailability

    var isDataAvailable: Bool {
        if case .available = availability {
            return true
        }
        return false
    }

    var isAvailable: Bool { isDataAvailable }

    var unavailableReasonText: String {
        if case .unavailable(let reason) = availability {
            return reason
        }
        return ""
    }

    var unavailableSymbolName: String { symbolName }

    var displayValueText: String {
        isDataAvailable ? valueText : IndicatorFallbackPresentation.unknownValueText
    }

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
    let wifi: WiFiIndicatorState
    let speaker: ConnectivityIndicatorState
    let bluetooth: ConnectivityIndicatorState

    static let unavailable = ConnectivityState(
        wifi: .unavailable,
        speaker: .unavailable(title: "Speaker/Output", subtitle: "Output unavailable", symbolName: "speaker.slash.fill"),
        bluetooth: .unavailable(title: "Bluetooth", subtitle: "Status unavailable", symbolName: "bolt.horizontal")
    )
}
