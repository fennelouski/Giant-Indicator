import SwiftUI

struct ContentView: View {
    private let placeholders: [IndicatorPlaceholder] = [
        .init(title: "Battery", value: "87%", symbol: "battery.75"),
        .init(title: "Volume", value: "42%", symbol: "speaker.wave.2.fill"),
        .init(title: "Playback", value: "Playing", symbol: "play.fill")
    ]

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            GeometryReader { proxy in
                let columns = gridColumns(for: proxy.size.width)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(placeholders) { placeholder in
                        IndicatorTile(placeholder: placeholder)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }

    private func gridColumns(for width: CGFloat) -> [GridItem] {
        let desiredTileWidth: CGFloat = 220
        let count = max(Int(width / desiredTileWidth), 1)
        return Array(
            repeating: GridItem(.flexible(minimum: 160, maximum: 420), spacing: 16),
            count: count
        )
    }
}

private struct IndicatorPlaceholder: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let symbol: String
}

private struct IndicatorTile: View {
    let placeholder: IndicatorPlaceholder

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: placeholder.symbol)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(.white)

            Text(placeholder.value)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(placeholder.title)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview("Dashboard") {
    ContentView()
}

#Preview("Compact Dashboard", traits: .fixedLayout(width: 350, height: 750)) {
    ContentView()
}
