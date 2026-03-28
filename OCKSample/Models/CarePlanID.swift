//
//  CarePlanID.swift
//  OCKSample
//
//  Created by Alarik Damrow on 3/28/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

// TODO: Add CarePlans specific to your app here.
// If you don't remember what a OCKCarePlan is, read the CareKit docs.
enum CarePlanID: String, CaseIterable, Identifiable {
    var id: Self { self }
    case health // Add custom id's for your Care Plans, these are examples
    case wellness
    case nutrition
}
