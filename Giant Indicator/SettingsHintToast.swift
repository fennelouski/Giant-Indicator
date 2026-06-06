//
//  SettingsHintToast.swift
//  Giant Indicator
//

import SwiftUI

struct SettingsHintToast: View {
    @Environment(\.dashboardPalette) private var palette
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(palette.foreground)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                Capsule(style: .continuous)
                    .fill(palette.foreground(opacity: 0.16))
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(palette.foreground(opacity: 0.28), lineWidth: 1)
                    }
            }
            .accessibilityIdentifier("settings-hint-toast")
    }
}
