//
//  SettingsHintPresenter.swift
//  Giant Indicator
//

import Combine
import Foundation

@MainActor
final class SettingsHintPresenter: ObservableObject {
    static let message = "Double tap to open settings"

    @Published private(set) var isVisible = false

    private var lastShownAt: Date?
    private var dismissTask: Task<Void, Never>?
    private let cooldown: TimeInterval
    private let displayDuration: TimeInterval
    private let now: () -> Date

    init(
        cooldown: TimeInterval = 10,
        displayDuration: TimeInterval = 2.5,
        now: @escaping () -> Date = Date.init
    ) {
        self.cooldown = cooldown
        self.displayDuration = displayDuration
        self.now = now
    }

    func requestPresentation() {
        guard !isVisible else { return }
        if let lastShownAt,
           now().timeIntervalSince(lastShownAt) < cooldown {
            return
        }

        dismissTask?.cancel()
        isVisible = true
        lastShownAt = now()

        dismissTask = Task { [displayDuration] in
            try? await Task.sleep(for: .seconds(displayDuration))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        isVisible = false
    }
}
