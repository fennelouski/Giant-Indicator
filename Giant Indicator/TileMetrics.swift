//
//  TileMetrics.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct TileMetrics {
    /// Minimum tile height for readable standard layout (icon + value + label).
    static let minimumReadableTileHeight: CGFloat = 130

    let width: CGFloat
    let height: CGFloat

    private var compactDimension: CGFloat {
        min(width, height)
    }

    private var sizeScale: CGFloat {
        Swift.min(1, height / Self.minimumReadableTileHeight)
    }

    /// Approximate vertical space for the current tile metrics (icon + primary [+ subtitle]).
    var minimumContentHeight: CGFloat {
        let verticalPadding = padding * 2
        let primaryText = max(
            valueFontSize,
            max(clockTimeFontSize, max(dateTextFontSize, batteryPercentageFontSize))
        )
        let glyphHeight = min(iconHeight, primaryText * 0.55)
        let compactStack = verticalPadding + contentSpacing + glyphHeight + primaryText * 1.05

        guard height >= Self.minimumReadableTileHeight * 0.95 else {
            return compactStack
        }

        return compactStack + contentSpacing + subtitleFontSize * 0.9
    }

    var contentSpacing: CGFloat {
        clamp(compactDimension * 0.1, min: boundedMin(10, 0.06), max: min(24, height * 0.12))
    }

    var padding: CGFloat {
        clamp(compactDimension * 0.12, min: boundedMin(16, 0.1), max: min(30, height * 0.14))
    }

    var iconHeight: CGFloat {
        clamp(height * 0.32, min: boundedMin(44, 0.22), max: min(96, height * 0.42))
    }

    var symbolFontSize: CGFloat {
        clamp(compactDimension * 0.22, min: boundedMin(40, 0.2), max: min(78, height * 0.35))
    }

    var valueFontSize: CGFloat {
        clamp(height * 0.24, min: boundedMin(34, 0.18), max: min(66, height * 0.32))
    }

    /// Primary battery percentage typography (PR-17: percentage-first at a distance).
    var batteryPercentageFontSize: CGFloat {
        clamp(height * 0.34, min: boundedMin(48, 0.24), max: min(92, height * 0.45))
    }

    /// Primary clock time typography (PR-24: large at-a-distance time).
    var clockTimeFontSize: CGFloat {
        clamp(height * 0.36, min: boundedMin(52, 0.26), max: min(96, height * 0.48))
    }

    /// Primary date typography (PR-26: large at-a-distance date).
    var dateTextFontSize: CGFloat {
        clamp(height * 0.28, min: boundedMin(40, 0.2), max: min(80, height * 0.4))
    }

    /// Secondary fill icon under the percentage (PR-17).
    var batteryIconHeight: CGFloat {
        clamp(height * 0.2, min: boundedMin(32, 0.14), max: min(64, height * 0.28))
    }

    var titleFontSize: CGFloat {
        clamp(height * 0.1, min: boundedMin(18, 0.09), max: min(28, height * 0.14))
    }

    var subtitleFontSize: CGFloat {
        clamp(height * 0.085, min: boundedMin(15, 0.075), max: min(22, height * 0.12))
    }

    var cornerRadius: CGFloat {
        clamp(compactDimension * 0.12, min: boundedMin(18, 0.1), max: min(30, height * 0.16))
    }

    private func boundedMin(_ preferredMinimum: CGFloat, _ heightFraction: CGFloat) -> CGFloat {
        let scaledPreferred = preferredMinimum * sizeScale
        return min(scaledPreferred, max(4, height * heightFraction))
    }

    private func clamp(_ value: CGFloat, min minimum: CGFloat, max maximum: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, minimum), maximum)
    }
}
