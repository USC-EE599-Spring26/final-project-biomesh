//
//  ColorStyler.swift
//  OCKSample
//
//  Created by Ray on 02/03/2026.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKitUI
import SwiftUI
import UIKit

struct ColorStyler: OCKColorStyler {
    #if os(iOS) || os(visionOS)

    // MARK: - BioMesh Blue + Yellow Theme

    // Deep blue (primary brand color)
    private var bioBluePrimary: UIColor { UIColor(red: 0.00, green: 0.35, blue: 0.75, alpha: 1.0) }

    // Soft blue background (light mode)
    private var bioBlueLightBackground: UIColor { UIColor(red: 0.80, green: 0.90, blue: 1.00, alpha: 1.0) }

    // Dark mode blue background
    private var bioBlueDarkBackground: UIColor { UIColor(red: 0.05, green: 0.15, blue: 0.35, alpha: 1.0) }

    // Bright yellow accent
    private var bioYellowAccent: UIColor { UIColor(red: 1.00, green: 0.85, blue: 0.10, alpha: 1.0) }

    // Softer yellow background areas
    private var bioYellowLightBackground: UIColor { UIColor(red: 1.00, green: 0.96, blue: 0.70, alpha: 1.0) }

    // MARK: - Labels

    var label: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        }
    }

    var secondaryLabel: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 0.8, alpha: 1.0)
                : UIColor.darkGray
        }
    }

    // MARK: - REQUIRED CHANGE #1
    // Tint color (buttons, checkmarks, progress rings, etc.)
    var tintColor: UIColor { bioBluePrimary }

    // MARK: - REQUIRED CHANGE #2
    // Main app background
    var customBackground: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? self.bioBlueDarkBackground
                : self.bioBlueLightBackground
        }
    }

    // MARK: - REQUIRED CHANGE #3
    // Grouped background (section backgrounds)
    var customGroupedBackground: UIColor { bioYellowLightBackground }

    // MARK: - REQUIRED CHANGE #4
    // Card fill background
    var customFill: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 1.0)
                : UIColor.white
        }
    }

    // Optional separator tweak (extra polish)
    var separator: UIColor { bioYellowAccent }

    #endif
}
