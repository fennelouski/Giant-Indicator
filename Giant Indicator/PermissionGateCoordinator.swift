//
//  PermissionGateCoordinator.swift
//  Giant Indicator
//

import Combine
import SwiftUI

struct PermissionAlertModel: Identifiable {
    let id = UUID()
    let permission: PermissionKind
    let title: String
    let message: String
}

/// Gates indicator enablement behind per-permission educational consent (PR-27).
@MainActor
final class PermissionGateCoordinator: ObservableObject {
    @Published var pendingAlert: PermissionAlertModel?

    private var pendingEnableIndicator: IndicatorKind?
    private var pendingPermissions: [PermissionKind] = []
    private var pendingPermissionIndex = 0

    var onIndicatorEnabled: ((IndicatorKind) -> Void)?
    var onIndicatorDisabled: ((IndicatorKind) -> Void)?

    func setIndicatorVisibility(
        _ isVisible: Bool,
        for kind: IndicatorKind,
        currentVisibility: inout [IndicatorKind: Bool]
    ) {
        if isVisible {
            attemptEnableIndicator(kind, currentVisibility: &currentVisibility)
        } else {
            currentVisibility[kind] = false
            IndicatorPreferences.setVisibility(false, for: kind)
            onIndicatorDisabled?(kind)
        }
    }

    private func attemptEnableIndicator(
        _ kind: IndicatorKind,
        currentVisibility: inout [IndicatorKind: Bool]
    ) {
        let required = Array(PermissionKind.required(for: kind)).sorted { $0.rawValue < $1.rawValue }
        guard !required.isEmpty else {
            applyIndicatorEnable(kind, currentVisibility: &currentVisibility)
            return
        }

        pendingEnableIndicator = kind
        pendingPermissions = required
        pendingPermissionIndex = 0
        presentNextEducationOrProceed(currentVisibility: &currentVisibility)
    }

    private func presentNextEducationOrProceed(currentVisibility: inout [IndicatorKind: Bool]) {
        while pendingPermissionIndex < pendingPermissions.count {
            let permission = pendingPermissions[pendingPermissionIndex]
            let status = PermissionAuthorizationReader.status(for: permission)

            if status == .authorized {
                pendingPermissionIndex += 1
                continue
            }

            if !PermissionEducationPreferences.hasSeenEducation(for: permission) {
                pendingAlert = PermissionAlertModel(
                    permission: permission,
                    title: permission.educationTitle,
                    message: permission.educationMessage
                )
                return
            }

            pendingPermissionIndex += 1
        }

        finishEnablingIndicator(currentVisibility: &currentVisibility)
    }

    func confirmEducation(currentVisibility: inout [IndicatorKind: Bool]) {
        guard let alert = pendingAlert else { return }
        PermissionEducationPreferences.markEducationSeen(for: alert.permission)
        pendingAlert = nil
        pendingPermissionIndex += 1
        presentNextEducationOrProceed(currentVisibility: &currentVisibility)
    }

    func cancelEducation(currentVisibility: inout [IndicatorKind: Bool]) {
        guard let kind = pendingEnableIndicator else {
            pendingAlert = nil
            return
        }
        pendingAlert = nil
        pendingEnableIndicator = nil
        pendingPermissions = []
        pendingPermissionIndex = 0
        currentVisibility[kind] = false
    }

    private func finishEnablingIndicator(currentVisibility: inout [IndicatorKind: Bool]) {
        guard let kind = pendingEnableIndicator else { return }
        pendingEnableIndicator = nil
        pendingPermissions = []
        pendingPermissionIndex = 0
        applyIndicatorEnable(kind, currentVisibility: &currentVisibility)
    }

    private func applyIndicatorEnable(
        _ kind: IndicatorKind,
        currentVisibility: inout [IndicatorKind: Bool]
    ) {
        currentVisibility[kind] = true
        IndicatorPreferences.setVisibility(true, for: kind)
        onIndicatorEnabled?(kind)
    }
}
