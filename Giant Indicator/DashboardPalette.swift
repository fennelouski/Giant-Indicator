//
//  DashboardPalette.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

enum DashboardBackgroundAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

struct DashboardPalette: Equatable {
    let background: Color
    let foreground: Color

    init(colorScheme: ColorScheme) {
        if colorScheme == .dark {
            background = .black
            foreground = .white
        } else {
            background = .white
            foreground = .black
        }
    }

    init(batteryPercentage: Int) {
        let brightness = BatteryReflectiveBackground.brightness(forPercentage: batteryPercentage)
        background = Color(white: brightness)
        foreground = brightness < 0.5 ? .white : .black
    }

    func foreground(opacity: Double) -> Color {
        foreground.opacity(opacity)
    }

    var gearButtonFill: Color {
        foreground(opacity: 0.12)
    }

    var gearButtonStroke: Color {
        foreground(opacity: 0.2)
    }

    var tileMutedFill: Color {
        foreground(opacity: 0.34)
    }

    var tileDimmedFill: Color {
        foreground(opacity: 0.28)
    }

    var titleText: Color {
        foreground(opacity: 0.95)
    }

    var subtitleText: Color {
        foreground(opacity: 0.86)
    }

    var mutedText: Color {
        foreground(opacity: 0.78)
    }

    var secondaryText: Color {
        foreground(opacity: 0.75)
    }

    var inactiveFill: Color {
        foreground(opacity: 0.28)
    }

    var trackFill: Color {
        foreground(opacity: 0.34)
    }
}

private struct DashboardPaletteKey: EnvironmentKey {
    static let defaultValue = DashboardPalette(colorScheme: .dark)
}

extension EnvironmentValues {
    var dashboardPalette: DashboardPalette {
        get { self[DashboardPaletteKey.self] }
        set { self[DashboardPaletteKey.self] = newValue }
    }
}

private struct DashboardPaletteEnvironmentModifier: ViewModifier {
    @Environment(\.colorScheme) private var systemColorScheme
    let backgroundAppearance: DashboardBackgroundAppearance
    let batteryReflectiveBackground: Bool
    let batteryPercentage: Int
    let batteryDataAvailable: Bool

    func body(content: Content) -> some View {
        content.environment(\.dashboardPalette, resolvedPalette)
    }

    private var resolvedPalette: DashboardPalette {
        if batteryReflectiveBackground {
            let percentage = batteryDataAvailable ? batteryPercentage : 0
            return DashboardPalette(batteryPercentage: percentage)
        }
        return DashboardPalette(colorScheme: resolvedColorScheme)
    }

    private var resolvedColorScheme: ColorScheme {
        switch backgroundAppearance {
        case .system:
            return systemColorScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

extension View {
    func dashboardPaletteEnvironment(
        backgroundAppearance: DashboardBackgroundAppearance,
        batteryReflectiveBackground: Bool,
        batteryPercentage: Int,
        batteryDataAvailable: Bool
    ) -> some View {
        modifier(
            DashboardPaletteEnvironmentModifier(
                backgroundAppearance: backgroundAppearance,
                batteryReflectiveBackground: batteryReflectiveBackground,
                batteryPercentage: batteryPercentage,
                batteryDataAvailable: batteryDataAvailable
            )
        )
    }
}
