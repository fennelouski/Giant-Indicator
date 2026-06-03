import SwiftUI

struct WeatherAttributionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dashboardPalette) private var palette
    let attribution: WeatherAttributionData

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                if let markURL {
                    AsyncImage(url: markURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 18)
                        default:
                            Text("Apple Weather")
                                .font(.caption)
                                .foregroundStyle(palette.mutedText)
                        }
                    }
                } else {
                    Text("Apple Weather")
                        .font(.caption)
                        .foregroundStyle(palette.mutedText)
                }
                if let legalPageURL = attribution.legalPageURL {
                    Link("Data sources and legal details", destination: legalPageURL)
                        .font(.footnote)
                        .foregroundStyle(palette.mutedText)
                }
            }

            if let legalText = attribution.legalAttributionText, !legalText.isEmpty {
                Text(legalText)
                    .font(.caption2)
                    .foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.center)
            } else if attribution.legalPageURL == nil {
                Text("Weather information is provided by Apple Weather and its data providers.")
                    .font(.caption2)
                    .foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityIdentifier("weather-attribution-view")
    }

    private var markURL: URL? {
        colorScheme == .dark ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL
    }
}
