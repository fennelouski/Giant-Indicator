//
//  ClockTypography.swift
//  Giant Indicator
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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
        let attributes: [NSAttributedString.Key: Any] = [.font: clockFont(size: fontSize)]
        let size = (text as NSString).size(withAttributes: attributes)
        return ceil(size.width)
    }

    #if canImport(UIKit)
    private static func clockFont(size: CGFloat) -> UIFont {
        let monospaced = UIFont.monospacedDigitSystemFont(ofSize: size, weight: .heavy)
        if let roundedDescriptor = monospaced.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: roundedDescriptor, size: size)
        }
        return monospaced
    }
    #elseif canImport(AppKit)
    private static func clockFont(size: CGFloat) -> NSFont {
        let monospaced = NSFont.monospacedDigitSystemFont(ofSize: size, weight: .heavy)
        if let descriptor = monospaced.fontDescriptor.withDesign(.rounded),
           let rounded = NSFont(descriptor: descriptor, size: size) {
            return rounded
        }
        return monospaced
    }
    #endif
}
