//
//  IndicatorPreferences.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import Foundation

enum IndicatorPreferences {
    static let defaults = UserDefaults.standard

    static var allVisibilityKeys: [String] {
        IndicatorKind.allCases.map(\.visibilityStorageKey)
    }

    static func loadVisibility() -> [IndicatorKind: Bool] {
        var visibility = IndicatorKind.defaultVisibilityState

        for kind in IndicatorKind.allCases {
            let key = kind.visibilityStorageKey
            if defaults.object(forKey: key) != nil {
                visibility[kind] = defaults.bool(forKey: key)
            }
        }

        return visibility
    }

    static func setVisibility(_ isVisible: Bool, for kind: IndicatorKind) {
        defaults.set(isVisible, forKey: kind.visibilityStorageKey)
    }

    static func resetVisibility() {
        allVisibilityKeys.forEach(defaults.removeObject(forKey:))
    }
}
