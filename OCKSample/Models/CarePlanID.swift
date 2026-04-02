//
//  CarePlanID.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

enum CarePlanID: String, CaseIterable, Identifiable {
    var id: Self { self }
    /// Tracks daily caffeine/water intake and anxiety episodes
    case dailyTracking = "dailyTracking"
    /// Manages sleep hygiene and evening routines
    case sleepWellness = "sleepWellness"
    /// Covers surveys, ROM checks, and quality-of-life assessments
    case assessment = "assessment"
}
