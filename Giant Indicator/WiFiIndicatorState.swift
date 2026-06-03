import CoreGraphics
import Foundation

enum WiFiLinkStatus: Equatable {
    case connected
    case disconnected
}

enum WiFiSignalStrength: Equatable {
    case known(percentage: Int)
    case unavailable(reason: String)
    case notApplicable
}

enum WiFiSignalStrengthCapability {
    static var isSupported: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
}

struct WiFiIndicatorState: Equatable, IndicatorUnavailablePresenting {
    let linkStatus: WiFiLinkStatus
    let signal: WiFiSignalStrength
    let networkName: String?
    let showsNetworkName: Bool
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

    var unavailableSymbolName: String { "wifi.slash" }

    var isConnected: Bool {
        linkStatus == .connected
    }

    var showsSignalStrength: Bool {
        WiFiSignalStrengthCapability.isSupported && signalPercentage != nil
    }

    var displaysNetworkNameAsPrimary: Bool {
        showsNetworkName && isConnected && networkName != nil
    }

    var signalPercentage: Int? {
        guard case .known(let percentage) = signal else { return nil }
        return percentage.clamped(to: 0...100)
    }

    var filledBarCount: Int {
        guard let percentage = signalPercentage else { return 0 }
        switch percentage {
        case 0:
            return 0
        case 1...25:
            return 1
        case 26...50:
            return 2
        case 51...75:
            return 3
        default:
            return 4
        }
    }

    var connectionValueText: String {
        switch linkStatus {
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected"
        }
    }

    var primaryValueText: String {
        guard isDataAvailable else { return IndicatorFallbackPresentation.unknownValueText }
        if displaysNetworkNameAsPrimary, let networkName {
            return networkName
        }
        if showsSignalStrength, let percentage = signalPercentage {
            return "\(percentage)%"
        }
        return connectionValueText
    }

    var subtitleText: String {
        guard isDataAvailable else { return "Wi-Fi status unavailable" }

        switch linkStatus {
        case .disconnected:
            return "No Wi-Fi link"
        case .connected:
            if displaysNetworkNameAsPrimary {
                if showsSignalStrength, let percentage = signalPercentage {
                    return "\(percentage)%"
                }
                return ""
            }
            if showsSignalStrength {
                return "Connected"
            }
            if WiFiSignalStrengthCapability.isSupported {
                return "Connected"
            }
            return "Wi-Fi active"
        }
    }

    var showsSubtitle: Bool {
        !subtitleText.isEmpty
    }

    var symbolName: String {
        guard isDataAvailable else { return unavailableSymbolName }
        return isConnected ? "wifi" : "wifi.slash"
    }

    var accessibilitySummary: String {
        guard isDataAvailable else {
            return "Wi-Fi unavailable, \(unavailableReasonText)"
        }

        var parts: [String] = []
        if let networkName, displaysNetworkNameAsPrimary {
            parts.append(networkName)
        }
        parts.append(isConnected ? "connected" : "disconnected")
        if showsSignalStrength, let percentage = signalPercentage {
            parts.append("signal \(percentage) percent")
        }
        return parts.joined(separator: ", ")
    }

    static let unavailable = WiFiIndicatorState(
        linkStatus: .disconnected,
        signal: .unavailable(reason: "Unavailable"),
        networkName: nil,
        showsNetworkName: false,
        availability: .unavailable(reason: "Unavailable")
    )

    static func disconnected(showsNetworkName: Bool = false) -> WiFiIndicatorState {
        WiFiIndicatorState(
            linkStatus: .disconnected,
            signal: .notApplicable,
            networkName: nil,
            showsNetworkName: showsNetworkName,
            availability: .available
        )
    }

    static func connected(
        signal: WiFiSignalStrength,
        networkName: String? = nil,
        showsNetworkName: Bool = false
    ) -> WiFiIndicatorState {
        WiFiIndicatorState(
            linkStatus: .connected,
            signal: signal,
            networkName: networkName,
            showsNetworkName: showsNetworkName,
            availability: .available
        )
    }
}

enum WiFiSignalStrengthMapping {
    static func percentage(fromRSSI rssi: Int) -> Int {
        let clamped = rssi.clamped(to: -100...(-30))
        let normalized = (Double(clamped + 100) / 70.0) * 100
        return Int(normalized.rounded()).clamped(to: 0...100)
    }
}

enum WiFiNetworkNameSanitizer {
    static func sanitized(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed == "Wi-Fi" || trimmed == "WLAN" {
            return nil
        }
        return trimmed
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
