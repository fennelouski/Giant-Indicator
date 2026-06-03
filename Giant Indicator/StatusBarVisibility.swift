//
//  StatusBarVisibility.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/3/26.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Whether the current platform exposes status bar visibility control (PR-23).
enum StatusBarVisibilityControl {
    static var isPlatformSupported: Bool {
        #if canImport(UIKit) && !os(macOS)
        true
        #else
        false
        #endif
    }

    static var unavailableReason: String {
        #if os(macOS)
        "Status bar control is not available on macOS."
        #else
        "Status bar control is unavailable on this platform."
        #endif
    }
}

struct StatusBarVisibilityModifier: ViewModifier {
    let isVisible: Bool

    func body(content: Content) -> some View {
        #if canImport(UIKit) && !os(macOS)
        content.statusBarHidden(!isVisible)
        #else
        content
        #endif
    }
}

extension View {
    func statusBarVisibility(_ isVisible: Bool) -> some View {
        modifier(StatusBarVisibilityModifier(isVisible: isVisible))
    }
}
