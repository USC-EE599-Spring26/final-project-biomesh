//
//  CarePlanID.swift
//  OCKSample
//
//  Created by Alarik Damrow on 3/28/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

enum CarePlanID: String, CaseIterable, Identifiable {
    var id: Self { self }

    case health
    case wellness
    case nutrition
    case study
    case recovery
}
