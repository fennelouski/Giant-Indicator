import CoreGraphics

enum VolumeAvailability: Equatable {
    case available
    case unavailable(reason: String)
}

struct VolumeState: Equatable {
    let percentage: Int
    let availability: VolumeAvailability

    var normalizedLevel: CGFloat {
        CGFloat(percentage.clamped(to: 0...100)) / 100
    }

    var percentageText: String {
        "\(percentage.clamped(to: 0...100))%"
    }

    var isAvailable: Bool {
        if case .available = availability {
            return true
        }
        return false
    }

    var unavailableReason: String {
        if case .unavailable(let reason) = availability {
            return reason
        }
        return ""
    }

    var symbolName: String {
        let clamped = percentage.clamped(to: 0...100)
        switch clamped {
        case 0:
            return "speaker.slash.fill"
        case 1...33:
            return "speaker.wave.1.fill"
        case 34...66:
            return "speaker.wave.2.fill"
        default:
            return "speaker.wave.3.fill"
        }
    }

    static let unavailable = VolumeState(
        percentage: 0,
        availability: .unavailable(reason: "Unavailable")
    )
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
