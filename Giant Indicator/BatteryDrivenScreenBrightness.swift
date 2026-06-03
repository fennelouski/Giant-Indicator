//
//  BatteryDrivenScreenBrightness.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/3/26.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Maps battery level to system screen brightness (PR-22).
enum BatteryDrivenScreenBrightness {
    static let minimumScreenBrightness = 0.10
    static let fullBatteryPercentage = 100

    static func normalizedLevel(forPercentage percentage: Int) -> Double {
        let clamped = Swift.min(Swift.max(percentage, 0), fullBatteryPercentage)
        return Double(clamped) / Double(fullBatteryPercentage)
    }

    /// Screen brightness in `0...1`: `max(normalized^2, 0.10)`.
    static func screenBrightness(forPercentage percentage: Int) -> Double {
        let normalized = normalizedLevel(forPercentage: percentage)
        let squared = normalized * normalized
        return Swift.max(squared, minimumScreenBrightness)
    }
}

/// Whether the current platform exposes writable screen brightness (PR-22).
enum ScreenBrightnessControl {
    static var isPlatformSupported: Bool {
        #if canImport(UIKit) && !os(macOS)
        true
        #else
        false
        #endif
    }

    static var unavailableReason: String {
        #if os(macOS)
        "Screen brightness control is not available on macOS."
        #else
        "Screen brightness control is unavailable on this platform."
        #endif
    }
}

struct BatteryDrivenScreenBrightnessModifier: ViewModifier {
    let isEnabled: Bool
    let batteryPercentage: Int
    let isDataAvailable: Bool

    @Environment(\.scenePhase) private var scenePhase
    #if canImport(UIKit) && !os(macOS)
    @State private var brightnessBeforeControl: CGFloat?
    #endif

    func body(content: Content) -> some View {
        content
            .onAppear { updateBrightnessControl() }
            .onDisappear { stopBrightnessControl() }
            .onChange(of: isEnabled) { _, _ in updateBrightnessControl() }
            .onChange(of: batteryPercentage) { _, _ in updateBrightnessControl() }
            .onChange(of: isDataAvailable) { _, _ in updateBrightnessControl() }
            .onChange(of: scenePhase) { _, _ in updateBrightnessControl() }
    }

    private var shouldControlBrightness: Bool {
        isEnabled && scenePhase == .active && ScreenBrightnessControl.isPlatformSupported
    }

    private func updateBrightnessControl() {
        if shouldControlBrightness {
            applyBatteryDrivenBrightness()
        } else {
            stopBrightnessControl()
        }
    }

    private func applyBatteryDrivenBrightness() {
        #if canImport(UIKit) && !os(macOS)
        let percentage = isDataAvailable ? batteryPercentage : 0
        let target = CGFloat(
            BatteryDrivenScreenBrightness.screenBrightness(forPercentage: percentage)
        )
        if brightnessBeforeControl == nil {
            brightnessBeforeControl = UIScreen.main.brightness
        }
        UIScreen.main.brightness = target
        #endif
    }

    private func stopBrightnessControl() {
        #if canImport(UIKit) && !os(macOS)
        guard let brightnessBeforeControl else { return }
        UIScreen.main.brightness = brightnessBeforeControl
        self.brightnessBeforeControl = nil
        #endif
    }
}

extension View {
    func batteryDrivenScreenBrightness(
        isEnabled: Bool,
        batteryPercentage: Int,
        isDataAvailable: Bool
    ) -> some View {
        modifier(
            BatteryDrivenScreenBrightnessModifier(
                isEnabled: isEnabled,
                batteryPercentage: batteryPercentage,
                isDataAvailable: isDataAvailable
            )
        )
    }
}
