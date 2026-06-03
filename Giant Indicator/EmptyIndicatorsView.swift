//
//  EmptyIndicatorsView.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct EmptyIndicatorsView: View {
    @Environment(\.dashboardPalette) private var palette
    let openSettings: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 60, weight: .bold))
                .foregroundStyle(palette.mutedText)

            Text("No indicators enabled")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(palette.foreground)
                .multilineTextAlignment(.center)

            Text("Open Settings to choose indicators.")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(palette.mutedText)
                .multilineTextAlignment(.center)

            Button("Open Settings") {
                openSettings()
            }
            .buttonStyle(.borderedProminent)
            .tint(palette.gearButtonFill)
            .foregroundStyle(palette.foreground)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
