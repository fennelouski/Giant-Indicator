import SwiftUI

struct WeatherAttributionView: View {
    @Environment(\.colorScheme) private var colorScheme
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
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                } else {
                    Text("Apple Weather")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                if let legalPageURL = attribution.legalPageURL {
                    Link("Weather data attribution", destination: legalPageURL)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            if let legalText = attribution.legalAttributionText, !legalText.isEmpty {
                Text(legalText)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
            } else if attribution.legalPageURL == nil {
                Text("Weather data by Apple Weather and data providers.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityIdentifier("weather-attribution-view")
    }

    private var markURL: URL? {
        colorScheme == .dark ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL
    }
}
