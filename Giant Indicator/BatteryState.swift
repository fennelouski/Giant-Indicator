import CoreGraphics

enum BatteryAvailability: Equatable {
    case available
    case unavailable(reason: String)
}

enum BatteryPowerConnection: Equatable {
    case pluggedIn
    case unplugged
}

enum BatteryChargingState: Equatable {
    case onBattery
    case charging
    case pluggedNotCharging
}

struct BatteryState: Equatable, IndicatorUnavailablePresenting {
    let percentage: Int
    let chargingState: BatteryChargingState
    let powerConnection: BatteryPowerConnection
    let availability: BatteryAvailability

    init(
        percentage: Int,
        chargingState: BatteryChargingState = .onBattery,
        availability: BatteryAvailability
    ) {
        self.percentage = percentage
        self.chargingState = chargingState
        self.powerConnection = Self.powerConnection(from: chargingState)
        self.availability = availability
    }

    init(
        percentage: Int,
        powerConnection: BatteryPowerConnection,
        availability: BatteryAvailability
    ) {
        self.init(
            percentage: percentage,
            chargingState: Self.chargingState(from: powerConnection),
            availability: availability
        )
    }

    var isPluggedIn: Bool {
        chargingState != .onBattery
    }

    var powerConnectionText: String {
        switch powerConnection {
        case .pluggedIn:
            return "Plugged In"
        case .unplugged:
            return "Unplugged"
        }
    }

    var chargingStateText: String {
        switch chargingState {
        case .onBattery:
            return "On Battery"
        case .charging:
            return "Charging"
        case .pluggedNotCharging:
            return "Plugged In"
        }
    }

    var chargingStateSymbolName: String {
        switch chargingState {
        case .onBattery:
            return "battery.100percent"
        case .charging:
            return "bolt.batteryblock.fill"
        case .pluggedNotCharging:
            return "powerplug.fill"
        }
    }

    static func powerConnection(from chargingState: BatteryChargingState) -> BatteryPowerConnection {
        switch chargingState {
        case .onBattery:
            return .unplugged
        case .charging, .pluggedNotCharging:
            return .pluggedIn
        }
    }

    private static func chargingState(from powerConnection: BatteryPowerConnection) -> BatteryChargingState {
        switch powerConnection {
        case .pluggedIn:
            return .pluggedNotCharging
        case .unplugged:
            return .onBattery
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
