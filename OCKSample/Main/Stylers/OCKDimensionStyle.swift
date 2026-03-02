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
    
    // BioMesh spacing scale (soft, breathable layout)
    
    // Small spacing (tight grouping)
    var pointSize1: CGFloat { 4 }
    
    // Standard small padding
    var pointSize2: CGFloat { 8 }
    
    // Medium spacing between elements
    var pointSize3: CGFloat { 12 }
    
    // Default card padding
    var pointSize4: CGFloat { 16 }
    
    // Larger section spacing
    var pointSize5: CGFloat { 24 }
}
