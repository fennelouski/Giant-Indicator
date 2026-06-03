import CoreGraphics

enum BatteryAvailability: Equatable {
    case available
    case unavailable(reason: String)
}

enum BatteryPowerConnection: Equatable {
    case pluggedIn
    case unplugged
}

struct BatteryState: Equatable, IndicatorUnavailablePresenting {
    let percentage: Int
    let powerConnection: BatteryPowerConnection
    let availability: BatteryAvailability

    init(
        percentage: Int,
        powerConnection: BatteryPowerConnection = .unplugged,
        availability: BatteryAvailability
    ) {
        self.percentage = percentage
        self.powerConnection = powerConnection
        self.availability = availability
    }

    var isPluggedIn: Bool {
        powerConnection == .pluggedIn
    }

    var powerConnectionText: String {
        switch powerConnection {
        case .pluggedIn:
            return "Plugged In"
        case .unplugged:
            return "Unplugged"
        }
    }

    var normalizedLevel: CGFloat {
        CGFloat(percentage).clamped(to: 0...100) / 100
    }

    var percentageText: String {
        "\(percentage.clamped(to: 0...100))%"
    }

    var isAvailable: Bool { isDataAvailable }

    var isDataAvailable: Bool {
        if case .available = availability {
            return true
        }
        return false
    }

    var unavailableReason: String { unavailableReasonText }

    var unavailableReasonText: String {
        if case .unavailable(let reason) = availability {
            return reason
        }
        return ""
    }

    var unavailableSymbolName: String { "batteryblock.slash" }

    func fillWidth(in totalWidth: CGFloat) -> CGFloat {
        max(0, totalWidth) * normalizedLevel
    }

    static let unavailable = BatteryState(
        percentage: 0,
        powerConnection: .unplugged,
        availability: .unavailable(reason: "Unavailable")
    )
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
