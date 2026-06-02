//
//  DisplayPreferences.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import Foundation

enum DisplayPreferences {
    static let defaults = UserDefaults.standard
    private static let keepScreenOnKey = "display.keepScreenOn"

    /// Defaults to enabled: the dashboard is meant to stay visible across the room (PR-14).
    static var keepScreenOn: Bool {
        get {
            guard defaults.object(forKey: keepScreenOnKey) != nil else {
                return true
            }
            return defaults.bool(forKey: keepScreenOnKey)
        }
        set {
            defaults.set(newValue, forKey: keepScreenOnKey)
        }
    }

    static func reset() {
        defaults.removeObject(forKey: keepScreenOnKey)
    }
}
