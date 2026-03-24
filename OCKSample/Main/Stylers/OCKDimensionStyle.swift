//
//  OCKDimensionStyle.swift
//  OCKSample
//
//  Created by Ray Zhang on 3/2/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
//  BioMesh spacing & sizing configuration.
//  This file customizes layout density to create a calm,
//  breathable health-tracking interface.
//

import CareKitUI
import UIKit

struct OCKDimensionStyle: OCKDimensionStyler {

    // CHANGES (all updated values)
    var pointSize1: CGFloat { 6 }    // was 4
    var pointSize2: CGFloat { 10 }   // was 8
    var pointSize3: CGFloat { 14 }   // was 12
    var pointSize4: CGFloat { 18 }   // was 16
    var pointSize5: CGFloat { 30 }   // was 24
}
