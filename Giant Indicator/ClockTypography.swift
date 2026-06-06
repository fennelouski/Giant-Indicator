//
//  ClockTypography.swift
//  Giant Indicator
//

import UIKit

enum ClockTypography {
    static func fittedFontSize(
        text: String,
        maxFontSize: CGFloat,
        availableWidth: CGFloat
    ) -> CGFloat {
        guard maxFontSize > 0 else { return 1 }
        guard availableWidth > 0 else { return maxFontSize }
        if textWidth(text, fontSize: maxFontSize) <= availableWidth {
            return maxFontSize
        }

        var low: CGFloat = 1
        var high = maxFontSize
        while high - low > 0.5 {
            let mid = (low + high) / 2
            if textWidth(text, fontSize: mid) <= availableWidth {
                low = mid
            } else {
                high = mid
            }
        }
        return max(1, low)
    }

    static func textWidth(_ text: String, fontSize: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: clockUIFont(size: fontSize)]
        let size = (text as NSString).size(withAttributes: attributes)
        return ceil(size.width)
    }

    private static func clockUIFont(size: CGFloat) -> UIFont {
        let monospaced = UIFont.monospacedDigitSystemFont(ofSize: size, weight: .heavy)
        if let roundedDescriptor = monospaced.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: roundedDescriptor, size: size)
        }
        return monospaced
    }
}
