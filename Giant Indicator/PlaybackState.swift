enum PlaybackStatus: Equatable {
    case playing
    case paused
    case stopped
    case unavailable(reason: String)
}

struct PlaybackState: Equatable, IndicatorUnavailablePresenting {
    let status: PlaybackStatus

    var titleText: String {
        switch status {
        case .playing:
            return "Playing"
        case .paused:
            return "Paused"
        case .stopped:
            return "Stopped"
        case .unavailable:
            return "--"
        }
    }

    var subtitleText: String {
        switch status {
        case .playing:
            return "Media Active"
        case .paused:
            return "Media Paused"
        case .stopped:
            return "No Active Media"
        case .unavailable(let reason):
            return reason
        }
    }

    var symbolName: String {
        switch status {
        case .playing:
            return "play.fill"
        case .paused:
            return "pause.fill"
        case .stopped:
            return "stop.fill"
        case .unavailable:
            return "questionmark.circle"
        }
    }

    var isAvailable: Bool { isDataAvailable }

    var isDataAvailable: Bool {
        if case .unavailable = status {
            return false
        }
        return true
    }

    var unavailableReasonText: String {
        if case .unavailable(let reason) = status {
            return reason
        }
        return ""
    }

    var unavailableSymbolName: String { "questionmark.circle" }

    static let stopped = PlaybackState(status: .stopped)
    static let unavailable = PlaybackState(status: .unavailable(reason: "Unavailable"))
}
