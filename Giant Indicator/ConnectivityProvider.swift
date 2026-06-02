import Combine
import Foundation
import Network

#if canImport(AVFoundation)
import AVFoundation
#endif

#if canImport(CoreBluetooth)
import CoreBluetooth
#endif

protocol ConnectivityProviding {
    func connectivityPublisher() -> AnyPublisher<ConnectivityState, Never>
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
    private var bluetoothValue = "Off"
    private var bluetoothSubtitle = "Bluetooth is turned off"
    private var bluetoothSymbol = "bolt.horizontal.slash"
    private var bluetoothAvailability: ConnectivityAvailability = .available
    private var cancellables = Set<AnyCancellable>()

    init(processInfo: ProcessInfo = .processInfo) {
        self.processInfo = processInfo
        super.init()
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
        wifiMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            self.wifiConnected = path.status == .satisfied
            self.publishSnapshot()
        }
        wifiMonitor.start(queue: monitorQueue)

        #if canImport(CoreBluetooth)
        bluetoothManager = CBCentralManager(delegate: self, queue: monitorQueue)
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

        publishSnapshot()
    }

    private func publishSnapshot() {
        let wifiState = makeWiFiState()
        let speakerState = makeSpeakerState()
        let bluetoothState = makeBluetoothState()
        let ringerState = makeRingerState()

        subject.send(
            ConnectivityState(
                wifi: wifiState,
                speaker: speakerState,
                bluetooth: bluetoothState,
                ringer: ringerState
            )
        )
    }

    private func makeWiFiState() -> ConnectivityIndicatorState {
        ConnectivityIndicatorState(
            title: "Wi-Fi",
            valueText: wifiConnected ? "Connected" : "Disconnected",
            subtitleText: wifiConnected ? "Wi-Fi active" : "No Wi-Fi link",
            symbolName: wifiConnected ? "wifi" : "wifi.slash",
            availability: .available
        )
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
                symbolName: "hifispeaker.slash",
                reason: "Audio Session Error"
            )
        }

        guard let outputPort = session.currentRoute.outputs.first else {
            return .unavailable(
                title: "Speaker/Output",
                subtitle: "No route detected",
                symbolName: "hifispeaker.slash",
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
            symbolName: "hifispeaker.slash",
            reason: "Unsupported"
        )
        #endif
    }

    private func makeBluetoothState() -> ConnectivityIndicatorState {
        ConnectivityIndicatorState(
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
        let speaker = uiTestArgumentValue(after: "--ui-testing-speaker-status", default: "speaker")
        let bluetooth = uiTestArgumentValue(after: "--ui-testing-bluetooth-status", default: "on")
        let ringer = uiTestArgumentValue(after: "--ui-testing-ringer-status", default: "unavailable")

        return ConnectivityState(
            wifi: connectivityStateForWiFi(wifi),
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

    private func connectivityStateForWiFi(_ value: String) -> ConnectivityIndicatorState {
        switch value {
        case "connected":
            return ConnectivityIndicatorState(
                title: "Wi-Fi",
                valueText: "Connected",
                subtitleText: "Wi-Fi active",
                symbolName: "wifi",
                availability: .available
            )
        case "disconnected":
            return ConnectivityIndicatorState(
                title: "Wi-Fi",
                valueText: "Disconnected",
                subtitleText: "No Wi-Fi link",
                symbolName: "wifi.slash",
                availability: .available
            )
        default:
            return .unavailable(
                title: "Wi-Fi",
                subtitle: "Wi-Fi status unavailable",
                symbolName: "wifi.slash",
                reason: "Unavailable"
            )
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
                symbolName: "hifispeaker.slash",
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
                symbolName: "bolt.horizontal.slash",
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
            bluetoothSymbol = "bolt.horizontal.slash"
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
