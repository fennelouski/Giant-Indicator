//
//  BatteryIcon.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct BatteryIcon: View {
    let level: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let capWidth = max(12, proxy.size.width * 0.05)
            let shellWidth = max(16, proxy.size.width - capWidth - 10)
            let strokeWidth: CGFloat = 4
            let contentPadding = strokeWidth + 5
            let contentWidth = max(0, shellWidth - contentPadding * 2)
            let clampedLevel = min(max(level, 0), 1)

            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white, lineWidth: strokeWidth)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white)
                            .frame(width: contentWidth * clampedLevel)
                            .padding(contentPadding)
                            .accessibilityHidden(true)
                    }
                    .frame(width: shellWidth)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white)
                    .frame(width: capWidth, height: max(18, proxy.size.height * 0.42))
            }
        }
    }
}
