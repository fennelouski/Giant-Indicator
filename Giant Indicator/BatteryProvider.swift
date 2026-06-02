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

        let notificationPublisher = NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification))
            .map { _ in snapshotUIKitBatteryState(device: device) }

        return Just(snapshotUIKitBatteryState(device: device))
            .merge(with: notificationPublisher)
            .removeDuplicates()
            .eraseToAnyPublisher()
        #elseif os(macOS)
        return Timer.publish(every: 30, on: .main, in: .common)
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

        return BatteryState(
            percentage: level,
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
    return BatteryState(percentage: percentage, availability: .available)
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
        return BatteryState(percentage: percentage, availability: .available)
    }

    return .unavailable
}
#endif
