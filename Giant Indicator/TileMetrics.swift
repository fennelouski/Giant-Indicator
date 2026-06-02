//
//  TileMetrics.swift
//  Giant Indicator
//
//  Created by Nathan Fennel on 6/2/26.
//

import SwiftUI

struct TileMetrics {
    let width: CGFloat
    let height: CGFloat

    private var compactDimension: CGFloat {
        min(width, height)
    }

    var contentSpacing: CGFloat {
        clamp(compactDimension * 0.1, min: 10, max: 24)
    }

    var padding: CGFloat {
        clamp(compactDimension * 0.12, min: 16, max: 30)
    }

    var iconHeight: CGFloat {
        clamp(height * 0.32, min: 44, max: 96)
    }

    var symbolFontSize: CGFloat {
        clamp(compactDimension * 0.22, min: 40, max: 78)
    }

    var valueFontSize: CGFloat {
        clamp(height * 0.24, min: 34, max: 66)
    }

    var titleFontSize: CGFloat {
        clamp(height * 0.1, min: 18, max: 28)
    }

    var subtitleFontSize: CGFloat {
        clamp(height * 0.085, min: 15, max: 22)
    }

    var cornerRadius: CGFloat {
        clamp(compactDimension * 0.12, min: 18, max: 30)
    }

    private func clamp(_ value: CGFloat, min minimum: CGFloat, max maximum: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, minimum), maximum)
    }
}
