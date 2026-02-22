//
//  OCKHealthKitPassthroughStore.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Updated by You on 2/21/26.
//

import Foundation
import CareKitEssentials
import CareKitStore
import HealthKit
import os.log
extension OCKHealthKitPassthroughStore {
    func populateDefaultHealthKitTasks(startDate: Date = Date()) async throws {
        let countUnit = HKUnit.count()
        let stepTargetValue = OCKOutcomeValue(
            2000.0,
            units: countUnit.unitString
        )
        let stepSchedule = OCKSchedule.dailyAtTime(
            hour: 8,
            minutes: 0,
            start: startDate,
            end: nil,
            text: nil,
            duration: .allDay,
            targetValues: [stepTargetValue]
        )
        var steps = OCKHealthKitTask(
            id: TaskID.steps,
            title: "Steps",
            carePlanUUID: nil,
            schedule: stepSchedule,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: .stepCount,
                quantityType: .cumulative,
                unit: countUnit
            )
        )
        steps.asset = "figure.walk"
        steps.tags = ["cardType:numericProgress"]
        do {
            _ = try await addTasks([steps])
        } catch {
            Logger.ockStore.info("HealthKit steps task already exists or could not be added: \(error)")
        }
    }
}
