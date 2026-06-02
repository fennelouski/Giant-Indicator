//
//  SettingsView.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var indicatorVisibility: [IndicatorKind: Bool]
    let indicatorKinds: [IndicatorKind]

    var body: some View {
        NavigationStack {
            List {
                Section("Visible Indicators") {
                    ForEach(indicatorKinds) { kind in
                        Toggle(isOn: binding(for: kind)) {
                            Label(kind.displayName, systemImage: kind.symbol)
                        }
                        .accessibilityIdentifier("indicator-toggle-\(kind.rawValue)")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .accessibilityIdentifier("settings-view")
    }

    private func binding(for kind: IndicatorKind) -> Binding<Bool> {
        Binding(
            get: { indicatorVisibility[kind, default: true] },
            set: { newValue in
                indicatorVisibility[kind] = newValue
                IndicatorPreferences.setVisibility(newValue, for: kind)
            }
        )
    }
}
