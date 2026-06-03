//
//  TileKindLabelVisibility.swift
//  Giant Indicator
//

import Foundation

/// Controls visibility of on-tile kind labels (e.g. "Battery", "Volume") during layout adaptation.
struct TileKindLabelVisibility: Equatable {
    private let hiddenKinds: Set<IndicatorKind>

    static let strippingOrder: [IndicatorKind] = [.volume, .chargingState]

    static let allVisible = TileKindLabelVisibility(hiddenKinds: [])

    static let hidingBatteryAndVolume = TileKindLabelVisibility(hiddenKinds: [.battery, .volume, .chargingState])

    /// Progressive states from most to least kind-label visibility.
    static let progressiveStrippingStates: [TileKindLabelVisibility] = {
        var states: [TileKindLabelVisibility] = [.allVisible]
        var hidden = Set<IndicatorKind>()
        for kind in strippingOrder {
            hidden.insert(kind)
            states.append(TileKindLabelVisibility(hiddenKinds: hidden))
        }
        return states
    }()

    func showsKindLabel(for kind: IndicatorKind) -> Bool {
        guard Self.strippingOrder.contains(kind) else { return true }
        return !hiddenKinds.contains(kind)
    }

    var visibleKindLabelCount: Int {
        Self.strippingOrder.filter { showsKindLabel(for: $0) }.count
    }

    var kindLabelScoreBonus: CGFloat {
        CGFloat(visibleKindLabelCount) * 25
    }

    private init(hiddenKinds: Set<IndicatorKind>) {
        self.hiddenKinds = hiddenKinds
    }
}
