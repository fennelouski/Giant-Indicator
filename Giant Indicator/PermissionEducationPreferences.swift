//
//  PermissionEducationPreferences.swift
//  Giant Indicator
//

import Foundation

enum PermissionEducationPreferences {
    static let defaults = UserDefaults.standard

    private static func storageKey(for kind: PermissionKind) -> String {
        "permission.education.seen.\(kind.rawValue)"
    }

    static func hasSeenEducation(for kind: PermissionKind) -> Bool {
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-skip-permission-education") {
            return true
        }
        return defaults.bool(forKey: storageKey(for: kind))
    }

    static func markEducationSeen(for kind: PermissionKind) {
        defaults.set(true, forKey: storageKey(for: kind))
    }

    static func reset() {
        PermissionKind.allCases.forEach { kind in
            defaults.removeObject(forKey: storageKey(for: kind))
        }
    }
}
