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

    func populateDefaultHealthKitTasks(
        _ patientUUID: UUID? = nil,
        startDate: Date = Date()
    ) async throws {

        #if os(iOS)
        let careStore: OCKStore = try await MainActor.run {
            guard let store = AppDelegateKey.defaultValue?.store else {
                throw AppError.couldntBeUnwrapped
            }
            return store
        }

        try await careStore.populateCarePlans(patientUUID: patientUUID)

        let carePlanUUIDs = try await OCKStore.getCarePlanUUIDs()
        let dailyTrackingUUID = carePlanUUIDs[.dailyTracking]
        let sleepWellnessUUID = carePlanUUIDs[.sleepWellness]
        #else
        let dailyTrackingUUID: UUID? = nil
        let sleepWellnessUUID: UUID? = nil
        #endif

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
            carePlanUUID: dailyTrackingUUID,
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
            carePlanUUID: sleepWellnessUUID,
            schedule: sleepSchedule,
            healthKitLinkage: OCKHealthKitLinkage(
                categoryIdentifier: .sleepAnalysis
            )
        )
        sleep.instructions = "Hours of sleep recorded by HealthKit. This is the key mediator between your caffeine intake and next-day anxiety."
        sleep.asset = "bed.double.fill"
        sleep.card = .labeledValue
        sleep.priority = 5

        _ = try await addTasksIfNotPresent([steps, sleep])
    }
}
