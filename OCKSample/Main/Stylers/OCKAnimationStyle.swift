//
//  OCKAnimationStyle.swift
//  OCKSample
//
//  Created by Faye on 2/28/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
//  TODO (Teammate 3): Customize the animation values below to match the BioMesh feel.
//  Only 1 change is required for OCKAnimationStyler per the assignment.
//

import CareKitUI
import SwiftUI

struct BioMeshAnimationStyle: OCKAnimationStyler {
    var defaultAnimation: Animation? { .easeInOut(duration: 0.35) }
}

