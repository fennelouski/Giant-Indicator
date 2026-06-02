//
//  VolumeIcon.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct VolumeIcon: View {
    let level: CGFloat
    let symbolName: String

    var body: some View {
        GeometryReader { proxy in
            let iconAreaWidth = proxy.size.width * 0.34
            let barAreaWidth = max(0, proxy.size.width - iconAreaWidth - 16)
            let clampedLevel = min(max(level, 0), 1)
            let barHeight = max(18, proxy.size.height * 0.28)

            HStack(spacing: 16) {
                Image(systemName: symbolName)
                    .font(.system(size: max(26, proxy.size.height * 0.5), weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: iconAreaWidth, alignment: .leading)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
                        .fill(Color.white.opacity(0.18))

                    RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
                        .fill(Color.white)
                        .frame(width: barAreaWidth * clampedLevel)
                }
                .frame(width: barAreaWidth, height: barHeight)
            }
        }
        .accessibilityHidden(true)
    }
}
