//
//  TaskID.swift
//  OCKSample
//
//  Created by Corey Baker on 4/14/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
enum TaskID {
    static let waterIntake = "default.waterIntake"
    static let caffeineIntake = "default.caffeineIntake"
    static let steps = "default.steps"
    static let mindfulness = "default.mindfulness"
    static let resourceOfTheDay = "default.resource"
    static let ordered: [String] = [
        waterIntake,
        caffeineIntake,
        steps,
        mindfulness,
        resourceOfTheDay
    ]
    static let orderedWatchOS: [String] = ordered
    static let orderedObjective: [String] = ordered
}
