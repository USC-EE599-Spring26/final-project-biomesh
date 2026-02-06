//
//  Styler.swift
//  OCKSample
//
//  Created by Corey Baker on 10/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import CareKitUI
import SwiftUI
import UIKit
struct Styler: OCKStyler {
    var color: OCKColorStyler {ColorStyler()}
    var dimension: OCKDimensionStyler {BlueWhiteDimensionStyler()}
    var animation: OCKAnimationStyler {BlueWhiteAnimationStyler()}
    var appearance: OCKAppearanceStyler {BlueWhiteAppearanceStyler()}
    struct BlueWhiteDimensionStyler: OCKDimensionStyler {

        // Change 1: corner radius
        var cornerRadius1: CGFloat { 18 }

        // Change 2: spacing between stacked elements
        var stackSpacing1: CGFloat { 12 }

        // Change 3: padding feel for content
        var paddedContentSpacing: CGFloat { 10 }

        // (Optional extra)
        var lineWidth1: CGFloat { 1.5 }
    }
    struct BlueWhiteAppearanceStyler: OCKAppearanceStyler {

        // Change 1: shadow opacity
        var shadowOpacity: Float { 0.18 }

        // Change 2: shadow radius
        var shadowRadius: CGFloat { 8 }

        // Change 3: shadow offset
        var shadowOffset: CGSize { CGSize(width: 0, height: 3) }
    }
    struct BlueWhiteAnimationStyler: OCKAnimationStyler {

        // Only 1 change required
        var defaultAnimation: Animation? { .easeInOut(duration: 0.35) }
    }
}
