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

#if canImport(UIKit) && !os(macOS)
/// Resolves the display's `UIScreen` from the hosting view hierarchy (iOS 26+).
private struct ScreenContextReader: UIViewRepresentable {
    var onScreenChange: (UIScreen?) -> Void

    final class ReaderView: UIView {
        var onScreenChange: ((UIScreen?) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            reportScreen()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            reportScreen()
        }

        fileprivate func reportScreen() {
            onScreenChange?(window?.windowScene?.screen)
        }
    }

    func makeUIView(context: Context) -> ReaderView {
        let view = ReaderView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.onScreenChange = onScreenChange
        return view
    }

    func updateUIView(_ uiView: ReaderView, context: Context) {
        uiView.onScreenChange = onScreenChange
        uiView.reportScreen()
    }
}
#endif

struct BatteryDrivenScreenBrightnessModifier: ViewModifier {
    let isEnabled: Bool
    let batteryPercentage: Int
    let isDataAvailable: Bool

    @Environment(\.scenePhase) private var scenePhase
    #if canImport(UIKit) && !os(macOS)
    @State private var activeScreen: UIScreen?
    @State private var brightnessBeforeControl: CGFloat?
    #endif

    func body(content: Content) -> some View {
        content
            .background {
                #if canImport(UIKit) && !os(macOS)
                ScreenContextReader { screen in
                    if let screen {
                        activeScreen = screen
                        updateBrightnessControl()
                    }
                }
                .frame(width: 0, height: 0)
                #endif
            }
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
        guard let activeScreen else { return }
        let percentage = isDataAvailable ? batteryPercentage : 0
        let target = CGFloat(
            BatteryDrivenScreenBrightness.screenBrightness(forPercentage: percentage)
        )
        if brightnessBeforeControl == nil {
            brightnessBeforeControl = activeScreen.brightness
        }
        activeScreen.brightness = target
        #endif
    }

    private func stopBrightnessControl() {
        #if canImport(UIKit) && !os(macOS)
        guard let activeScreen, let brightnessBeforeControl else { return }
        activeScreen.brightness = brightnessBeforeControl
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
