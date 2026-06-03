import SwiftUI

struct WiFiSignalBars: View {
    @Environment(\.dashboardPalette) private var palette
    let filledBarCount: Int
    let isActive: Bool

    private let barHeights: [CGFloat] = [0.45, 0.62, 0.78, 1.0]

    var body: some View {
        GeometryReader { proxy in
            let barWidth = max(6, proxy.size.width / 9)
            let maxBarHeight = proxy.size.height

            HStack(alignment: .bottom, spacing: barWidth * 0.35) {
                ForEach(0..<barHeights.count, id: \.self) { index in
                    let isFilled = index < filledBarCount
                    RoundedRectangle(cornerRadius: barWidth / 2.5, style: .continuous)
                        .fill(barColor(isFilled: isFilled))
                        .frame(
                            width: barWidth,
                            height: max(8, maxBarHeight * barHeights[index])
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .accessibilityHidden(true)
    }

    private func barColor(isFilled: Bool) -> Color {
        if !isActive {
            return palette.inactiveFill
        }
        return isFilled ? palette.foreground : palette.trackFill
    }
}
