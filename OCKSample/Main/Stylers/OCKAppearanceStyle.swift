//
//  OCKAppearanceStyle.swift
//  OCKSample
//
//  Created by Faye on 2/28/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
//  TODO (Teammate 3): Adjust the values below to finalize the BioMesh visual feel.
//  At least 3 changes are required for OCKAppearanceStyler per the assignment.
//

import CareKitUI
import UIKit

struct BioMeshAppearanceStyle: OCKAppearanceStyler {
    // Lighter, cleaner card shadow for BioMesh
    var shadowOpacity: Float { 0.08 }

    // Slightly softer blur for a modern iOS card feel
    var shadowRadius: CGFloat { 12 }

    // Gentle downward shadow (less harsh than 4)
    var shadowOffset: CGSize { CGSize(width: 0, height: 2) }
}
