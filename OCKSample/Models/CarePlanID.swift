//
//  CarePlanID.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

// TODO: Add CarePlans specific to your app here.
// If you don't remember what a OCKCarePlan is, read the CareKit docs.
enum CarePlanID: String, CaseIterable, Identifiable {
    var id: Self { self }
    case habits
    case sleep
    case anxiety
}
