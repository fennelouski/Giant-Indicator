import Combine
import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if os(macOS)
import IOKit.ps
#endif

protocol BatteryStateProviding {
    func batteryStatePublisher() -> AnyPublisher<BatteryState, Never>
}

struct SystemBatteryProvider: BatteryStateProviding {
    /// Polling interval when notifications are sparse or unavailable (simulator, macOS).
    static let pollingInterval: TimeInterval = 10

    private let processInfo: ProcessInfo

    init(processInfo: ProcessInfo = .processInfo) {
        self.processInfo = processInfo
    }

    func batteryStatePublisher() -> AnyPublisher<BatteryState, Never> {
        if let overrideState = makeUITestOverrideState() {
            return Just(overrideState).eraseToAnyPublisher()
        }

        #if canImport(UIKit)
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true

        let snapshot = { snapshotUIKitBatteryState(device: device) }

        let notificationPublisher = NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification))
            .map { _ in snapshot() }

        let timerPublisher = Timer.publish(every: Self.pollingInterval, on: .main, in: .common)
            .autoconnect()
            .map { _ in snapshot() }

        return notificationPublisher
            .merge(with: timerPublisher)
            .prepend(snapshot())
            .removeDuplicates()
            .eraseToAnyPublisher()
        #elseif os(macOS)
        return Timer.publish(every: Self.pollingInterval, on: .main, in: .common)
            .autoconnect()
            .map { _ in snapshotMacBatteryState() }
            .prepend(snapshotMacBatteryState())
            .removeDuplicates()
            .eraseToAnyPublisher()
        #else
        return Just(.unavailable).eraseToAnyPublisher()
        #endif
    }

    private func makeUITestOverrideState() -> BatteryState? {
        guard
            let argumentIndex = processInfo.arguments.firstIndex(of: "--ui-testing-battery-level"),
            processInfo.arguments.indices.contains(argumentIndex + 1),
            let level = Int(processInfo.arguments[argumentIndex + 1])
        else {
            return nil
        }

        let chargingState: BatteryChargingState
        if let chargingStateIndex = processInfo.arguments.firstIndex(of: "--ui-testing-battery-charging-state"),
           processInfo.arguments.indices.contains(chargingStateIndex + 1)
        {
            chargingState = uiTestChargingState(from: processInfo.arguments[chargingStateIndex + 1])
        } else if processInfo.arguments.contains("--ui-testing-battery-plugged-in") {
            chargingState = .charging
        } else if processInfo.arguments.contains("--ui-testing-battery-unplugged") {
            chargingState = .onBattery
        } else {
            chargingState = .onBattery
        }

        return BatteryState(
            percentage: level,
            chargingState: chargingState,
            availability: .available
        )
    }
}

#if canImport(UIKit)
private func snapshotUIKitBatteryState(device: UIDevice) -> BatteryState {
    let level = device.batteryLevel
    guard level >= 0 else {
        return .unavailable
    }

    let percentage = Int((level * 100).rounded())
    let chargingState = uiKitChargingState(from: device.batteryState)
    return BatteryState(percentage: percentage, chargingState: chargingState, availability: .available)
}

private func uiKitChargingState(from batteryState: UIDevice.BatteryState) -> BatteryChargingState {
    switch batteryState {
    case .charging:
        return .charging
    case .full:
        return .pluggedNotCharging
    case .unplugged, .unknown:
        return .onBattery
    @unknown default:
        return .onBattery
    }
}

private func uiTestChargingState(from argument: String) -> BatteryChargingState {
    switch argument {
    case "charging":
        return .charging
    case "plugged-not-charging":
        return .pluggedNotCharging
    default:
        return .onBattery
    }
}
#endif

#if os(macOS)
private func snapshotMacBatteryState() -> BatteryState {
    guard
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
        let sourceList = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]
    else {
        return .unavailable
    }

    for source in sourceList {
        guard
            let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
            let type = description[kIOPSTypeKey as String] as? String,
            type == kIOPSInternalBatteryType
        else {
            continue
        }

        let current = description[kIOPSCurrentCapacityKey as String] as? Int ?? 0
        let max = description[kIOPSMaxCapacityKey as String] as? Int ?? 0
        guard max > 0 else {
            return .unavailable
        }

        let percentage = Int((Double(current) / Double(max) * 100).rounded())
        let chargingState = macChargingState(from: description)
        return BatteryState(percentage: percentage, chargingState: chargingState, availability: .available)
    }

    return .unavailable
}

private func macChargingState(from description: [String: Any]) -> BatteryChargingState {
    guard let powerSourceState = description[kIOPSPowerSourceStateKey as String] as? String else {
        return .onBattery
    }

    guard powerSourceState == kIOPSACPowerKey else {
        return .onBattery
    }

    if let isCharging = description[kIOPSIsChargingKey as String] as? Bool, isCharging {
        return .charging
    }

    return .pluggedNotCharging
}
#endif
