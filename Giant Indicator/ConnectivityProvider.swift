import Combine
import Foundation
import Network

#if canImport(AVFoundation)
import AVFoundation
#endif

#if canImport(CoreBluetooth)
import CoreBluetooth
#endif

#if canImport(CoreWLAN)
import CoreWLAN
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(NetworkExtension)
import NetworkExtension
#endif

protocol ConnectivityProviding {
    func connectivityPublisher() -> AnyPublisher<ConnectivityState, Never>
    func updateShowWiFiNetworkName(_ enabled: Bool)
    func updateBluetoothMonitoringEnabled(_ enabled: Bool)
}

final class SystemConnectivityProvider: NSObject, ConnectivityProviding {
    private let processInfo: ProcessInfo
    private let monitorQueue = DispatchQueue(label: "giant-indicator.connectivity.wifi")
    private let wifiMonitor = NWPathMonitor(requiredInterfaceType: .wifi)
    private let subject = CurrentValueSubject<ConnectivityState, Never>(.unavailable)

    #if canImport(CoreBluetooth)
    private var bluetoothManager: CBCentralManager?
    #endif

    private var wifiConnected = false
    private var wifiNetworkName: String?
    private var showWiFiNetworkName = DisplayPreferences.showWiFiNetworkName
    private var bluetoothValue = "Off"
    private var bluetoothSubtitle = "Bluetooth is turned off"
    private var bluetoothSymbol = "antenna.radiowaves.left.and.right.slash"
    private var bluetoothAvailability: ConnectivityAvailability = .available
    private var cancellables = Set<AnyCancellable>()
    private var hasStartedMonitoring = false
    private var isBluetoothMonitoringEnabled = false

    init(processInfo: ProcessInfo = .processInfo) {
        self.processInfo = processInfo
        super.init()
        if processInfo.arguments.contains("--ui-testing-show-wifi-network-name") {
            showWiFiNetworkName = true
        }
    }

    func updateShowWiFiNetworkName(_ enabled: Bool) {
        guard showWiFiNetworkName != enabled else { return }
        showWiFiNetworkName = enabled
        if !enabled {
            wifiNetworkName = nil
        }
        refreshNetworkNameIfNeeded()
        publishSnapshot()
    }

    func updateBluetoothMonitoringEnabled(_ enabled: Bool) {
        guard isBluetoothMonitoringEnabled != enabled else { return }
        isBluetoothMonitoringEnabled = enabled

        #if canImport(CoreBluetooth)
        if enabled {
            startBluetoothMonitoringIfNeeded()
        } else {
            stopBluetoothMonitoring()
        }
        #endif

        publishSnapshot()
    }

    func connectivityPublisher() -> AnyPublisher<ConnectivityState, Never> {
        if let overrideState = makeUITestOverrideState() {
            return Just(overrideState).eraseToAnyPublisher()
        }

        startMonitoring()
        return subject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private func startMonitoring() {
        guard !hasStartedMonitoring else { return }
        hasStartedMonitoring = true

        wifiMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            self.wifiConnected = path.status == .satisfied
            if !self.wifiConnected {
                self.wifiNetworkName = nil
            }
            self.refreshNetworkNameIfNeeded()
            self.publishSnapshot()
        }
        wifiMonitor.start(queue: monitorQueue)

        #if canImport(CoreBluetooth)
        if isBluetoothMonitoringEnabled {
            startBluetoothMonitoringIfNeeded()
        }
        #else
        bluetoothValue = "--"
        bluetoothSubtitle = "Bluetooth controls are unavailable on this platform"
        bluetoothSymbol = "bolt.horizontal"
        bluetoothAvailability = .unavailable(reason: "Unsupported")
        #endif

        #if canImport(AVFoundation) && canImport(UIKit)
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .sink { [weak self] _ in self?.publishSnapshot() }
            .store(in: &cancellables)
        #endif

        #if os(macOS) && canImport(CoreWLAN)
        Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.wifiConnected else { return }
                self.refreshNetworkNameIfNeeded()
                self.publishSnapshot()
            }
            .store(in: &cancellables)
        #endif

        #if canImport(UIKit)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                self.refreshNetworkNameIfNeeded()
                self.publishSnapshot()
            }
            .store(in: &cancellables)
        #endif

        refreshNetworkNameIfNeeded()
        publishSnapshot()
    }

    private func publishSnapshot() {
        let wifiState = makeWiFiState()
        let speakerState = makeSpeakerState()
        let bluetoothState = makeBluetoothState()
        let ringerState = makeRingerState()

        let snapshot = ConnectivityState(
            wifi: wifiState,
            speaker: speakerState,
            bluetooth: bluetoothState,
            ringer: ringerState
        )

        guard subject.value != snapshot else { return }
        subject.send(snapshot)
    }

    private func makeWiFiState() -> WiFiIndicatorState {
        let showsName = showWiFiNetworkName

        guard wifiConnected else {
            return .disconnected(showsNetworkName: showsName)
        }

        return .connected(
            signal: resolvedSignalStrength(),
            networkName: showsName ? wifiNetworkName : nil,
            showsNetworkName: showsName
        )
    }

    private func resolvedSignalStrength() -> WiFiSignalStrength {
        guard WiFiSignalStrengthCapability.isSupported else {
            return .notApplicable
        }

        switch readSignalStrength() {
        case .known(let percentage):
            return .known(percentage: percentage)
        case .unavailable:
            return .notApplicable
        }
    }

    private enum SignalReadResult: Equatable {
        case known(percentage: Int)
        case unavailable
    }

    private func readSignalStrength() -> SignalReadResult {
        #if os(macOS) && canImport(CoreWLAN)
        guard let interface = CWWiFiClient.shared().interface() else {
            return .unavailable
        }

        let rssi = interface.rssiValue()
        guard rssi != 0 else {
            return .unavailable
        }

        return .known(percentage: WiFiSignalStrengthMapping.percentage(fromRSSI: rssi))
        #else
        return .unavailable
        #endif
    }

    private func refreshNetworkNameIfNeeded() {
        guard showWiFiNetworkName, wifiConnected else {
            wifiNetworkName = nil
            return
        }

        #if os(macOS) && canImport(CoreWLAN)
        wifiNetworkName = readNetworkNameSynchronously()
        #elseif canImport(NetworkExtension)
        NEHotspotNetwork.fetchCurrent { [weak self] network in
            guard let self else { return }
            let sanitized = WiFiNetworkNameSanitizer.sanitized(network?.ssid)
            self.monitorQueue.async {
                guard self.showWiFiNetworkName, self.wifiConnected else { return }
                guard self.wifiNetworkName != sanitized else { return }
                self.wifiNetworkName = sanitized
                DispatchQueue.main.async {
                    self.publishSnapshot()
                }
            }
        }
        #endif
    }

    private func readNetworkNameSynchronously() -> String? {
        #if os(macOS) && canImport(CoreWLAN)
        return WiFiNetworkNameSanitizer.sanitized(CWWiFiClient.shared().interface()?.ssid())
        #else
        return nil
        #endif
    }

    private func makeSpeakerState() -> ConnectivityIndicatorState {
        #if canImport(AVFoundation) && canImport(UIKit)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(true, options: [])
        } catch {
            return .unavailable(
                title: "Speaker/Output",
                subtitle: "Audio session unavailable",
                symbolName: "speaker.slash.fill",
                reason: "Audio Session Error"
            )
        }

        guard let outputPort = session.currentRoute.outputs.first else {
            return .unavailable(
                title: "Speaker/Output",
                subtitle: "No route detected",
                symbolName: "speaker.slash.fill",
                reason: "No Active Route"
            )
        }

        let output = outputDescription(for: outputPort.portType)
        return ConnectivityIndicatorState(
            title: "Speaker/Output",
            valueText: output.value,
            subtitleText: output.subtitle,
            symbolName: output.symbol,
            availability: .available
        )
        #else
        return .unavailable(
            title: "Speaker/Output",
            subtitle: "Output route unsupported",
            symbolName: "speaker.slash.fill",
            reason: "Unsupported"
        )
        #endif
    }

    #if canImport(CoreBluetooth)
    private func startBluetoothMonitoringIfNeeded() {
        guard isBluetoothMonitoringEnabled, bluetoothManager == nil else { return }
        bluetoothManager = CBCentralManager(delegate: self, queue: monitorQueue)
    }

    private func stopBluetoothMonitoring() {
        bluetoothManager = nil
        bluetoothValue = "Off"
        bluetoothSubtitle = "Bluetooth is turned off"
        bluetoothSymbol = "antenna.radiowaves.left.and.right.slash"
        bluetoothAvailability = .available
    }
    #endif

    private func makeBluetoothState() -> ConnectivityIndicatorState {
        #if canImport(CoreBluetooth)
        if !isBluetoothMonitoringEnabled {
            return ConnectivityIndicatorState(
                title: "Bluetooth",
                valueText: "Off",
                subtitleText: "Enable in Settings to monitor Bluetooth",
                symbolName: "antenna.radiowaves.left.and.right.slash",
                availability: .available
            )
        }
        #endif

        return ConnectivityIndicatorState(
            title: "Bluetooth",
            valueText: bluetoothValue,
            subtitleText: bluetoothSubtitle,
            symbolName: bluetoothSymbol,
            availability: bluetoothAvailability
        )
    }

    private func makeRingerState() -> ConnectivityIndicatorState {
        #if canImport(UIKit)
        ConnectivityIndicatorState.unavailable(
            title: "Ringer/Silent",
            subtitle: "iOS does not expose ringer switch state",
            symbolName: "bell.slash",
            reason: "Platform Limited"
        )
        #else
        ConnectivityIndicatorState.unavailable(
            title: "Ringer/Silent",
            subtitle: "Ringer mode is not available on this platform",
            symbolName: "bell.slash",
            reason: "Unsupported"
        )
        #endif
    }

    #if canImport(AVFoundation) && canImport(UIKit)
    private func outputDescription(for port: AVAudioSession.Port) -> (value: String, subtitle: String, symbol: String) {
        switch port {
        case .builtInSpeaker:
            return ("Speaker", "Built-in speaker", "hifispeaker.fill")
        case .headphones, .headsetMic:
            return ("Headphones", "Wired output", "headphones")
        case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
            return ("Bluetooth", "Bluetooth output", "dot.radiowaves.left.and.right")
        case .airPlay:
            return ("AirPlay", "Wireless output", "airplayaudio")
        default:
            return ("Other", "External output", "speaker.wave.2.fill")
        }
    }
    #endif

    private func makeUITestOverrideState() -> ConnectivityState? {
        guard processInfo.arguments.contains("--ui-testing-connectivity-override") else {
            return nil
        }

        let wifi = uiTestArgumentValue(after: "--ui-testing-wifi-status", default: "connected")
        let wifiSignal = uiTestArgumentValue(after: "--ui-testing-wifi-signal", default: "72")
        let wifiSSID = uiTestSSIDArgument()
        let showWiFiName = processInfo.arguments.contains("--ui-testing-show-wifi-network-name")
        let speaker = uiTestArgumentValue(after: "--ui-testing-speaker-status", default: "speaker")
        let bluetooth = uiTestArgumentValue(after: "--ui-testing-bluetooth-status", default: "on")
        let ringer = uiTestArgumentValue(after: "--ui-testing-ringer-status", default: "unavailable")

        return ConnectivityState(
            wifi: wifiStateForUITest(
                linkStatus: wifi,
                signal: wifiSignal,
                networkName: wifiSSID,
                showsNetworkName: showWiFiName || wifiSSID != nil
            ),
            speaker: connectivityStateForSpeaker(speaker),
            bluetooth: connectivityStateForBluetooth(bluetooth),
            ringer: connectivityStateForRinger(ringer)
        )
    }

    private func uiTestArgumentValue(after argument: String, default defaultValue: String) -> String {
        guard
            let index = processInfo.arguments.firstIndex(of: argument),
            processInfo.arguments.indices.contains(index + 1)
        else {
            return defaultValue
        }

        return processInfo.arguments[index + 1].lowercased()
    }

    private func uiTestSSIDArgument() -> String? {
        guard
            let index = processInfo.arguments.firstIndex(of: "--ui-testing-wifi-ssid"),
            processInfo.arguments.indices.contains(index + 1)
        else {
            return nil
        }

        return WiFiNetworkNameSanitizer.sanitized(processInfo.arguments[index + 1])
    }

    private func wifiStateForUITest(
        linkStatus: String,
        signal: String,
        networkName: String?,
        showsNetworkName: Bool
    ) -> WiFiIndicatorState {
        switch linkStatus {
        case "connected":
            return .connected(
                signal: wifiSignalForUITest(signal),
                networkName: networkName,
                showsNetworkName: showsNetworkName
            )
        case "disconnected":
            return .disconnected(showsNetworkName: showsNetworkName)
        default:
            return .unavailable
        }
    }

    private func wifiSignalForUITest(_ value: String) -> WiFiSignalStrength {
        switch value {
        case "unavailable":
            return .unavailable(reason: "Signal strength unavailable on this platform")
        case "not-applicable", "n/a":
            return .notApplicable
        default:
            if let percentage = Int(value) {
                let clamped = Swift.min(100, Swift.max(0, percentage))
                return .known(percentage: clamped)
            }
            return .known(percentage: 72)
        }
    }

    private func connectivityStateForSpeaker(_ value: String) -> ConnectivityIndicatorState {
        switch value {
        case "speaker":
            return ConnectivityIndicatorState(
                title: "Speaker/Output",
                valueText: "Speaker",
                subtitleText: "Built-in speaker",
                symbolName: "hifispeaker.fill",
                availability: .available
            )
        case "headphones":
            return ConnectivityIndicatorState(
                title: "Speaker/Output",
                valueText: "Headphones",
                subtitleText: "Wired output",
                symbolName: "headphones",
                availability: .available
            )
        case "bluetooth":
            return ConnectivityIndicatorState(
                title: "Speaker/Output",
                valueText: "Bluetooth",
                subtitleText: "Bluetooth output",
                symbolName: "dot.radiowaves.left.and.right",
                availability: .available
            )
        default:
            return .unavailable(
                title: "Speaker/Output",
                subtitle: "Output route unavailable",
                symbolName: "speaker.slash.fill",
                reason: "Unavailable"
            )
        }
    }

    private func connectivityStateForBluetooth(_ value: String) -> ConnectivityIndicatorState {
        switch value {
        case "on":
            return ConnectivityIndicatorState(
                title: "Bluetooth",
                valueText: "On",
                subtitleText: "Bluetooth enabled",
                symbolName: "bolt.horizontal",
                availability: .available
            )
        case "off":
            return ConnectivityIndicatorState(
                title: "Bluetooth",
                valueText: "Off",
                subtitleText: "Bluetooth is turned off",
                symbolName: "antenna.radiowaves.left.and.right.slash",
                availability: .available
            )
        default:
            return .unavailable(
                title: "Bluetooth",
                subtitle: "Bluetooth status unavailable",
                symbolName: "bolt.horizontal",
                reason: "Unavailable"
            )
        }
    }

    private func connectivityStateForRinger(_ value: String) -> ConnectivityIndicatorState {
        switch value {
        case "ring":
            return ConnectivityIndicatorState(
                title: "Ringer/Silent",
                valueText: "Ring",
                subtitleText: "Audible alerts enabled",
                symbolName: "bell.fill",
                availability: .available
            )
        case "silent":
            return ConnectivityIndicatorState(
                title: "Ringer/Silent",
                valueText: "Silent",
                subtitleText: "Muted alerts",
                symbolName: "bell.slash.fill",
                availability: .available
            )
        default:
            return .unavailable(
                title: "Ringer/Silent",
                subtitle: "Status not exposed by API",
                symbolName: "bell.slash",
                reason: "Platform Limited"
            )
        }
    }
}

#if canImport(CoreBluetooth)
extension SystemConnectivityProvider: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            bluetoothValue = "On"
            bluetoothSubtitle = "Bluetooth enabled"
            bluetoothSymbol = "bolt.horizontal"
            bluetoothAvailability = .available
        case .poweredOff:
            bluetoothValue = "Off"
            bluetoothSubtitle = "Bluetooth is turned off"
            bluetoothSymbol = "antenna.radiowaves.left.and.right.slash"
            bluetoothAvailability = .available
        case .unauthorized:
            bluetoothValue = "--"
            bluetoothSubtitle = "Bluetooth permission denied"
            bluetoothSymbol = "bolt.horizontal"
            bluetoothAvailability = .unavailable(reason: "Permission Denied")
        case .unsupported:
            bluetoothValue = "--"
            bluetoothSubtitle = "Bluetooth unsupported"
            bluetoothSymbol = "bolt.horizontal"
            bluetoothAvailability = .unavailable(reason: "Unsupported")
        default:
            bluetoothValue = "--"
            bluetoothSubtitle = "Bluetooth unavailable"
            bluetoothSymbol = "bolt.horizontal"
            bluetoothAvailability = .unavailable(reason: "Unavailable")
        }
        publishSnapshot()
    }
}
#endif
