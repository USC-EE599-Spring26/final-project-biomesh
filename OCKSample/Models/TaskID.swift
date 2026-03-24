//
//  TaskID.swift
//  OCKSample
//
//  Created by Corey Baker on 4/14/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

enum TaskID {
    // Default OCKTask IDs
    static let caffeineIntake   = "biomesh.caffeine"
    static let waterIntake      = "biomesh.water"
    static let anxietyCheck     = "biomesh.anxiety"
    static let sleepHygiene     = "biomesh.sleep.hygiene"
    static let qualityOfLife    = "biomesh.qualityOfLife"
    // Default OCKHealthKitTask IDs
    static let steps            = "biomesh.steps"
    static let sleepDuration    = "biomesh.sleep.duration"

    // Ordered display lists
    static var ordered: [String] {
        orderedObjective + orderedSubjective
    }

    /// HealthKit-backed tasks shown first
    static var orderedObjective: [String] {
        [steps, sleepDuration]
    }

    /// Self-reported tasks shown after HealthKit
    static var orderedSubjective: [String] {
        [caffeineIntake, waterIntake, anxietyCheck, sleepHygiene]
    }

    static var orderedWatchOS: [String] {
        [caffeineIntake, waterIntake, anxietyCheck]
    }
}
