import SwiftUI

struct WeatherAttributionView: View {
    @Environment(\.colorScheme) private var colorScheme
    let attribution: WeatherAttributionData

    var body: some View {
        Group {
            if let legalPageURL = attribution.legalPageURL {
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
                                Image(systemName: "cloud.sun")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                    }

                    Link("Weather data attribution", destination: legalPageURL)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.8))
                }
            } else if let legalText = attribution.legalAttributionText, !legalText.isEmpty {
                Text(legalText)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityIdentifier("weather-attribution-view")
    }

    private var markURL: URL? {
        colorScheme == .dark ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL
    }
}
