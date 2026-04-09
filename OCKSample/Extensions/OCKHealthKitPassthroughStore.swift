//
//  OCKHealthKitPassthroughStore.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitEssentials
import CareKitStore
import HealthKit
import os.log

extension OCKHealthKitPassthroughStore {
    /*
         TODO completed:
         - CarePlan is linked through carePlanUUID
         - Patient is stored in task metadata because OCKTask does not
           provide a direct patientUUID property
         */
    func populateDefaultHealthKitTasks(
        _ patientUUID: UUID? = nil,
        carePlanUUID: UUID? = nil,
        startDate: Date = Date()
    ) async throws {

        // Daily Steps
        let countUnit = HKUnit.count()
        let stepSchedule = OCKSchedule.dailyAtTime(
            hour: 8,
            minutes: 0,
            start: startDate,
            end: nil,
            text: nil,
            duration: .allDay,
            targetValues: [OCKOutcomeValue(8000.0, units: countUnit.unitString)]
        )

        var steps = OCKHealthKitTask(
            id: TaskID.steps,
            title: "Daily Steps",
            carePlanUUID: carePlanUUID,
            schedule: stepSchedule,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: .stepCount,
                quantityType: .cumulative,
                unit: countUnit
            )
        )
        steps.instructions = "Your step count from HealthKit. Regular movement can reduce caffeine-related anxiety symptoms."
        steps.asset = "figure.walk"
        steps.card = .numericProgress
        steps.priority = 4

        // Append metadata tags instead of overwriting existing tags
        var stepTags = steps.tags ?? []
        if let patientUUID {
            stepTags.append("patient:\(patientUUID.uuidString)")
        }
        if let carePlanUUID {
            stepTags.append("carePlan:\(carePlanUUID.uuidString)")
        }
        steps.tags = stepTags

        // Sleep Duration
        let sleepSchedule = OCKSchedule.dailyAtTime(
            hour: 7,
            minutes: 0,
            start: startDate,
            end: nil,
            text: nil,
            duration: .allDay,
            targetValues: []
        )

        var sleep = OCKHealthKitTask(
            id: TaskID.sleepDuration,
            title: "Sleep Duration",
            carePlanUUID: carePlanUUID,
            schedule: sleepSchedule,
            healthKitLinkage: OCKHealthKitLinkage(
                categoryIdentifier: .sleepAnalysis
            )
        )
        sleep.instructions = "Hours of sleep recorded by HealthKit. This is the key mediator between your caffeine intake and next-day anxiety."
        sleep.asset = "bed.double.fill"
        sleep.card = .labeledValue
        sleep.priority = 5

        var sleepTags = sleep.tags ?? []
        if let patientUUID {
            sleepTags.append("patient:\(patientUUID.uuidString)")
        }
        if let carePlanUUID {
            sleepTags.append("carePlan:\(carePlanUUID.uuidString)")
        }
        sleep.tags = sleepTags

        _ = try await addTasksIfNotPresent([steps, sleep])
    }
}
