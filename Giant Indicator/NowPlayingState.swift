struct NowPlayingMetadata: Equatable {
    let title: String
    let artist: String?
    let album: String?
}

enum NowPlayingAvailability: Equatable {
    case active(NowPlayingMetadata)
    case inactive
    case unavailable(reason: String)
}

struct NowPlayingState: Equatable, IndicatorUnavailablePresenting {
    let availability: NowPlayingAvailability

    var titleText: String {
        switch availability {
        case .active(let metadata):
            return metadata.title
        case .inactive:
            return "Nothing Playing"
        case .unavailable:
            return IndicatorFallbackPresentation.unknownValueText
        }
    }

    var artistText: String? {
        switch availability {
        case .active(let metadata):
            return metadata.artist
        case .inactive:
            return "No Active Media"
        case .unavailable:
            return nil
        }
    }

    var albumText: String? {
        switch availability {
        case .active(let metadata):
            return metadata.album
        case .inactive, .unavailable:
            return nil
        }
    }

    var symbolName: String {
        switch availability {
        case .active:
            return "music.note"
        case .inactive:
            return "music.note.list"
        case .unavailable:
            return "questionmark.circle"
        }
    }

    var isDataAvailable: Bool {
        if case .unavailable = availability {
            return false
        }
        return true
    }

    var unavailableReasonText: String {
        if case .unavailable(let reason) = availability {
            return reason
        }
        return ""
    }

    var unavailableSymbolName: String { "questionmark.circle" }

    static let inactive = NowPlayingState(availability: .inactive)
    static let unavailable = NowPlayingState(availability: .unavailable(reason: "Unavailable"))
}
