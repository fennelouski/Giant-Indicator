import CoreGraphics

enum BatteryAvailability: Equatable {
    case available
    case unavailable(reason: String)
}

struct BatteryState: Equatable {
    let percentage: Int
    let availability: BatteryAvailability

    var normalizedLevel: CGFloat {
        CGFloat(percentage).clamped(to: 0...100) / 100
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

    func fillWidth(in totalWidth: CGFloat) -> CGFloat {
        max(0, totalWidth) * normalizedLevel
    }

    static let unavailable = BatteryState(percentage: 0, availability: .unavailable(reason: "Unavailable"))
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
