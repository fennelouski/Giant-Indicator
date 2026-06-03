//
//  IndicatorPlaceholder.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct IndicatorPlaceholder: Identifiable {
    let kind: IndicatorKind
    let value: String
    var subtitle: String?
    var attribution: WeatherAttributionData?
    var symbolOverride: String? = nil
    var showsUnavailableFallback: Bool = false

    var id: IndicatorKind { kind }
    var title: String { kind.displayName }
    var symbol: String { symbolOverride ?? kind.symbol }

    static func fromConnectivityIndicator(
        _ indicator: ConnectivityIndicatorState,
        kind: IndicatorKind
    ) -> IndicatorPlaceholder {
        IndicatorPlaceholder(
            kind: kind,
            value: indicator.displayValueText,
            subtitle: indicator.subtitleText,
            symbolOverride: indicator.symbolName,
            showsUnavailableFallback: !indicator.isDataAvailable
        )
    }

    static func fromBatteryChargingState(_ state: BatteryState) -> IndicatorPlaceholder {
        guard state.isDataAvailable else {
            return IndicatorPlaceholder(
                kind: .chargingState,
                value: IndicatorFallbackPresentation.unknownValueText,
                subtitle: state.unavailableReasonText,
                symbolOverride: state.unavailableSymbolName,
                showsUnavailableFallback: true
            )
        }

        return IndicatorPlaceholder(
            kind: .chargingState,
            value: state.chargingStateText,
            symbolOverride: state.chargingStateSymbolName
        )
    }

    static func fromWiFiState(_ state: WiFiIndicatorState) -> IndicatorPlaceholder {
        IndicatorPlaceholder(
            kind: .wifi,
            value: state.primaryValueText,
            subtitle: state.subtitleText,
            symbolOverride: state.symbolName,
            showsUnavailableFallback: !state.isDataAvailable
        )
    }

    static func fromWeatherState(_ state: WeatherDisplayState) -> IndicatorPlaceholder {
        guard let snapshot = state.snapshot else {
            let subtitle: String
            let symbolName: String
            switch state.permissionState {
            case .denied:
                subtitle = "Location access is off"
                symbolName = "location.slash.fill"
            case .restricted:
                subtitle = "Location access is restricted"
                symbolName = "location.slash.fill"
            case .unavailable:
                subtitle = "Location currently unavailable"
                symbolName = "location.slash.fill"
            case .notRequested:
                subtitle = "Enable in Settings to load weather"
                symbolName = "cloud.sun.fill"
            case .authorized, .none:
                subtitle = "Current Location"
                symbolName = "cloud.sun.fill"
            }

            let isLoading = state.errorMessage == nil &&
                state.permissionState != .denied &&
                state.permissionState != .restricted &&
                state.permissionState != .unavailable &&
                state.permissionState != .notRequested

            let valueText: String
            if let errorMessage = state.errorMessage {
                valueText = errorMessage
            } else if state.permissionState == .notRequested {
                valueText = "Weather"
            } else {
                valueText = IndicatorFallbackPresentation.unknownValueText
            }

            return IndicatorPlaceholder(
                kind: .weather,
                value: valueText,
                subtitle: isLoading ? "Loading…" : subtitle,
                attribution: nil,
                symbolOverride: symbolName,
                showsUnavailableFallback: !isLoading
            )
        }

        let measurement = Measurement(value: snapshot.temperatureCelsius, unit: UnitTemperature.celsius)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .short
        let value = formatter.string(from: measurement)

        var subtitle = snapshot.conditionDescription
        if let source = state.source {
            let sourceText = source == .fresh ? "Fresh" : "Cached"
            subtitle = "\(subtitle) · \(sourceText)"
        }

        return IndicatorPlaceholder(
            kind: .weather,
            value: value,
            subtitle: subtitle,
            attribution: state.attribution
        )
    }
}
