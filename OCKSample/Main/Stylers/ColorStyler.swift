//
//  ColorStyler.swift
//  OCKSample
//
//  Created by Corey Baker on 10/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import CareKitUI
import SwiftUI
import UIKit

struct ColorStyler: OCKColorStyler {
    #if os(iOS) || os(visionOS)
    var label: UIColor {
        //FontColorKey.defaultValue
        UIColor.systemBlue
    }
    var secondaryLabel: UIColor {
        UIColor.systemBlue.withAlphaComponent(0.75)
    }
    var tertiaryLabel: UIColor {
		//UIColor(Color.accentColor)
        UIColor.systemBlue.withAlphaComponent(0.5)
    }
    var systemGroupedBackground: UIColor {
        UIColor.white
    }
    var separator: UIColor {
        UIColor.systemBlue.withAlphaComponent(0.2)
    }
    #endif
}
