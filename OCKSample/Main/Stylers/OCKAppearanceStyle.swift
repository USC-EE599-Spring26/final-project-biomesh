//
//  OCKAppearanceStyle.swift
//  OCKSample
//
//  Created by Faye on 2/28/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
//  xTODO (Teammate 3): Adjust the values below to finalize the BioMesh visual feel.
//  At least 3 changes are required for OCKAppearanceStyler per the assignment.
//

import CareKitUI
import UIKit

struct BioMeshAppearanceStyle: OCKAppearanceStyler {

    // CHANGE #1
    var shadowOpacity: Float { 0.14 }     // was 0.08

    // CHANGE #2
    var shadowRadius: CGFloat { 16 }      // was 12

    // CHANGE #3
    var shadowOffset: CGSize { CGSize(width: 0, height: 4) } // was (0, 2)
}
