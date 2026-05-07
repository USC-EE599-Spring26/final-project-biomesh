//
//  Styler.swift
//  OCKSample
//
//  Created by Corey Baker on 10/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import CareKitUI

// Styler wires together all four sub-stylers.
// ColorStyler    — color palette         (edit ColorStyler.swift)
// DimensionStyle — spacing / sizing      (edit OCKDimensionStyle.swift — already exists)
// BioMeshAnimationStyle  — motion        (edit OCKAnimationStyle.swift)
// BioMeshAppearanceStyle — shadow / look (edit OCKAppearanceStyle.swift)
struct Styler: OCKStyler {

    // CHANGE #1: shared instance
    static let shared = Styler()

    // CHANGE #2: store instances (instead of recreating each access)
    private let bioColor = ColorStyler()
    private let bioDimension = OCKDimensionStyle()
    private let bioAnimation = BioMeshAnimationStyle()
    private let bioAppearance = BioMeshAppearanceStyle()

    // CHANGE #3: return stored stylers
    var color: OCKColorStyler { bioColor }
    var dimension: OCKDimensionStyler { bioDimension }
    var animation: OCKAnimationStyler { bioAnimation }
    var appearance: OCKAppearanceStyler { bioAppearance }
}
