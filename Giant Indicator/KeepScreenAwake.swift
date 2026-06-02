//
//  KeepScreenAwake.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct KeepScreenAwakeModifier: ViewModifier {
    let isEnabled: Bool
    @Environment(\.scenePhase) private var scenePhase

    #if os(macOS)
    @State private var activity: NSObjectProtocol?
    #endif

    func body(content: Content) -> some View {
        content
            .onAppear { updateKeepAwake() }
            .onDisappear { clearKeepAwake() }
            .onChange(of: isEnabled) { _, _ in updateKeepAwake() }
            .onChange(of: scenePhase) { _, _ in updateKeepAwake() }
    }

    private var shouldKeepAwake: Bool {
        isEnabled && scenePhase == .active
    }

    private func updateKeepAwake() {
        if shouldKeepAwake {
            enableKeepAwake()
        } else {
            clearKeepAwake()
        }
    }

    private func enableKeepAwake() {
        #if canImport(UIKit) && !os(macOS)
        UIApplication.shared.isIdleTimerDisabled = true
        #elseif os(macOS)
        guard activity == nil else { return }
        activity = ProcessInfo.processInfo.beginActivity(
            options: [.idleDisplaySleepDisabled, .userInitiated],
            reason: "Giant Indicator dashboard is visible"
        )
        #endif
    }

    private func clearKeepAwake() {
        #if canImport(UIKit) && !os(macOS)
        UIApplication.shared.isIdleTimerDisabled = false
        #elseif os(macOS)
        if let activity {
            ProcessInfo.processInfo.endActivity(activity)
            self.activity = nil
        }
        #endif
    }
}

extension View {
    func keepScreenAwake(_ isEnabled: Bool) -> some View {
        modifier(KeepScreenAwakeModifier(isEnabled: isEnabled))
    }
}
