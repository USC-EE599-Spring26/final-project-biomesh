//
//  TaskID.swift
//  OCKSample
//
//  Created by Corey Baker on 4/14/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

enum TaskID {
    // Custom OCKTask IDs counted toward the assignment
    static let caffeineIntake   = "biomesh.caffeine"
    static let waterIntake      = "biomesh.water"
    static let anxietyCheck     = "biomesh.anxiety"
    static let sleepHygiene     = "biomesh.sleep.hygiene"
    static let weeklyReflection = "biomesh.weekly.reflection"

    // Original sample-inspired OCKHealthKitTask IDs that may still be shown
    static let steps            = "biomesh.steps"
    static let sleepDuration    = "biomesh.sleep.duration"

    // New HealthKit-backed tasks counted toward the assignment
    static let heartRate        = "biomesh.heart.rate"
    static let restingHeartRate = "biomesh.resting.heart.rate"

    // Ordered display lists
    static var ordered: [String] {
        orderedObjective + orderedSubjective
    }

    /// HealthKit-backed tasks shown first
    static var orderedObjective: [String] {
        [restingHeartRate, heartRate, steps, sleepDuration]
    }

    /// Self-reported tasks shown after HealthKit
    static var orderedSubjective: [String] {
        [caffeineIntake, waterIntake, anxietyCheck, sleepHygiene, weeklyReflection]
    }

    static var orderedWatchOS: [String] {
        [caffeineIntake, waterIntake, anxietyCheck]
    }
}
