//
//  DashboardTileStyle.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

private struct DashboardTileContainerModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.dashboardPalette) private var palette
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                palette.foreground(opacity: tileFillOpacity),
                                palette.foreground(opacity: tileFillOpacity * 0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(palette.background, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay {
                        if colorSchemeContrast == .increased {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(palette.foreground(opacity: 0.58), lineWidth: 2)
                        }
                    }
                    .shadow(
                        color: .black.opacity(colorSchemeContrast == .increased ? 0 : 0.1),
                        radius: 12,
                        x: 0,
                        y: 5
                    )
            }
    }

    private var tileFillOpacity: Double {
        if colorSchemeContrast == .increased { return 0.2 }
        return palette.foreground == .white ? 0.14 : 0.07
    }
}

extension View {
    func dashboardTileContainer(cornerRadius: CGFloat) -> some View {
        modifier(DashboardTileContainerModifier(cornerRadius: cornerRadius))
    }
}
