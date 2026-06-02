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

    var id: IndicatorKind { kind }
    var title: String { kind.displayName }
    var symbol: String { symbolOverride ?? kind.symbol }

    static func fromWeatherState(_ state: WeatherDisplayState) -> IndicatorPlaceholder {
        guard let snapshot = state.snapshot else {
            let subtitle: String
            switch state.permissionState {
            case .denied:
                subtitle = "Location access is off"
            case .restricted:
                subtitle = "Location access is restricted"
            case .unavailable:
                subtitle = "Location currently unavailable"
            case .authorized, .none:
                subtitle = "Current Location"
            }

            return IndicatorPlaceholder(
                kind: .weather,
                value: state.errorMessage ?? "Loading…",
                subtitle: subtitle,
                attribution: nil
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
