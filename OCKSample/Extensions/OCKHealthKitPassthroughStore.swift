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

    func populateDefaultHealthKitTasks(startDate: Date = Date()) async throws {

        // Daily Steps
        // Physical activity as a control variable in the caffeine-anxiety model.
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
            carePlanUUID: nil,
            schedule: stepSchedule,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: .stepCount,
                quantityType: .cumulative,
                unit: countUnit
            )
        )
        steps.instructions = "Your step count from HealthKit. " +
            "Regular movement can reduce caffeine-related anxiety symptoms."
        steps.asset = "figure.walk"
        steps.card = .numericProgress
        steps.priority = 4

        // Sleep Duration
        // The mediator variable in the caffeine → sleep → anxiety research model.
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
            carePlanUUID: nil,
            schedule: sleepSchedule,
            healthKitLinkage: OCKHealthKitLinkage(
                categoryIdentifier: .sleepAnalysis
            )
        )
        sleep.instructions = "Hours of sleep recorded by HealthKit. " +
            "This is the key mediator between your caffeine intake and next-day anxiety."
        sleep.asset = "bed.double.fill"
        sleep.card = .labeledValue
        sleep.priority = 5

        _ = try await addOrUpdateTasks([steps, sleep])
    }
    func addOrUpdateTasks(_ tasks: [OCKHealthKitTask]) async throws -> [OCKHealthKitTask] {
        let ids = tasks.map { $0.id }

        var query = OCKTaskQuery(for: Date())
        query.ids = ids

        let existing = try await fetchTasks(query: query)
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        var addedOrUpdated: [OCKHealthKitTask] = []

        for task in tasks {
            if var existingTask = existingByID[task.id] {
                existingTask.title = task.title
                existingTask.instructions = task.instructions
                existingTask.asset = task.asset
                existingTask.schedule = task.schedule
                existingTask.healthKitLinkage = task.healthKitLinkage
                existingTask.userInfo = task.userInfo
                existingTask.tags = task.tags
                existingTask.carePlanUUID = task.carePlanUUID

                let updated = try await updateTask(existingTask)
                addedOrUpdated.append(updated)
            } else {
                let added = try await addTask(task)
                addedOrUpdated.append(added)
            }
        }

        return addedOrUpdated
    }
}
