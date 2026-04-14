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

        // Average Heart Rate
        let beatsPerMinute = HKUnit.count().unitDivided(by: .minute())
        let heartRateSchedule = OCKSchedule.dailyAtTime(
            hour: 13,
            minutes: 0,
            start: startDate,
            end: nil,
            text: nil,
            duration: .allDay,
            targetValues: []
        )

        var heartRate = OCKHealthKitTask(
            id: TaskID.heartRate,
            title: "Heart Rate Trend",
            carePlanUUID: carePlanUUID,
            schedule: heartRateSchedule,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: .heartRate,
                quantityType: .discrete,
                unit: beatsPerMinute
            )
        )
        heartRate.instructions = "Review your HealthKit heart rate trend to see whether high-caffeine days also feel more physically activating."
        heartRate.asset = "heart.fill"
        heartRate.card = .labeledValue
        heartRate.priority = 0

        var heartRateTags = heartRate.tags ?? []
        if let patientUUID {
            heartRateTags.append("patient:\(patientUUID.uuidString)")
        }
        if let carePlanUUID {
            heartRateTags.append("carePlan:\(carePlanUUID.uuidString)")
        }
        heartRate.tags = heartRateTags

        // Resting Heart Rate
        let restingHeartRateSchedule = OCKSchedule.dailyAtTime(
            hour: 8,
            minutes: 30,
            start: startDate,
            end: nil,
            text: nil,
            duration: .allDay,
            targetValues: []
        )

        var restingHeartRate = OCKHealthKitTask(
            id: TaskID.restingHeartRate,
            title: "Resting Heart Rate",
            carePlanUUID: carePlanUUID,
            schedule: restingHeartRateSchedule,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: .restingHeartRate,
                quantityType: .discrete,
                unit: beatsPerMinute
            )
        )
        restingHeartRate.instructions = "Use resting heart rate as a recovery signal alongside caffeine, hydration, and stress habits."
        restingHeartRate.asset = "waveform.path.ecg"
        restingHeartRate.card = .labeledValue
        restingHeartRate.priority = 1

        var restingHeartRateTags = restingHeartRate.tags ?? []
        if let patientUUID {
            restingHeartRateTags.append("patient:\(patientUUID.uuidString)")
        }
        if let carePlanUUID {
            restingHeartRateTags.append("carePlan:\(carePlanUUID.uuidString)")
        }
        restingHeartRate.tags = restingHeartRateTags

        _ = try await addTasksIfNotPresent([steps, sleep, heartRate, restingHeartRate])
    }
}
