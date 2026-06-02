//
//  DashboardTileStyle.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

private struct DashboardTileContainerModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(tileFillOpacity))
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(tileStrokeOpacity), lineWidth: tileStrokeWidth)
                    }
            }
    }

    private var tileFillOpacity: Double {
        colorSchemeContrast == .increased ? 0.2 : 0.14
    }

    private var tileStrokeOpacity: Double {
        colorSchemeContrast == .increased ? 0.58 : 0.4
    }

    private var tileStrokeWidth: CGFloat {
        colorSchemeContrast == .increased ? 2 : 1.5
    }
}

extension View {
    func dashboardTileContainer(cornerRadius: CGFloat) -> some View {
        modifier(DashboardTileContainerModifier(cornerRadius: cornerRadius))
    }
}
