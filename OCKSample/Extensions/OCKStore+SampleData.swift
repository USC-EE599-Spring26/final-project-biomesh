//
//  OCKStore+SampleData.swift
//  OCKSample
//
//  Created by Corey Baker on 5/6/25.
//  Updated by You on 2/21/26.
//

import CareKitStore
import Foundation
import os.log
extension OCKStore {
    func populateSampleOutcomes(startDate: Date) async throws {
        let yesterDay = Calendar.current.date(byAdding: .day, value: -1, to: Date())!.endOfDay
        guard yesterDay > startDate else {
            throw AppError.errorString("Start date must be before last night")
        }
        let dateInterval = DateInterval(start: startDate, end: yesterDay)
        let eventQuery = OCKEventQuery(dateInterval: dateInterval)
        let pastEvents = try await fetchEvents(query: eventQuery)
        let pastOutcomes: [OCKOutcome] = pastEvents.compactMap { event -> OCKOutcome? in
            let initialRandomDate = randomDate(event.scheduleEvent.start, end: event.scheduleEvent.end)
            switch event.task.id {
            case TaskID.waterIntake, TaskID.caffeineIntake:
                let values = (0..<Int.random(in: 0...4)).map { _ in
                    createOutcomeValue(true, createdDate: randomDate(event.scheduleEvent.start, end: event.scheduleEvent.end))
                }
                return addValuesToOutcome(values, for: event)
            case TaskID.steps:
                guard Bool.random() else { return nil }
                let steps = Int.random(in: 1000...12000)
                let value = createOutcomeValue(steps, createdDate: initialRandomDate)
                return addValuesToOutcome([value], for: event)
            case TaskID.mindfulness, TaskID.resourceOfTheDay:
                guard Bool.random() else { return nil }
                let value = createOutcomeValue(true, createdDate: initialRandomDate)
                return addValuesToOutcome([value], for: event)

            default:
                return nil
            }
        }
        do {
            let saved = try await addOutcomes(pastOutcomes)
            Logger.ockStore.info("Added sample \(saved.count) outcomes to OCKStore!")
        } catch {
            Logger.ockStore.error("Error adding sample outcomes: \(error)")
        }
    }
    private func createOutcomeValue(_ value: OCKOutcomeValueUnderlyingType, createdDate: Date) -> OCKOutcomeValue {
        var v = OCKOutcomeValue(value)
        v.createdDate = createdDate
        return v
    }
    private func addValuesToOutcome(
        _ values: [OCKOutcomeValue],
        for event: OCKEvent<OCKTask, OCKOutcome>
    ) -> OCKOutcome? {
        guard !values.isEmpty else { return nil }
        if var outcome = event.outcome {
            outcome.values.append(contentsOf: values)
            outcome.effectiveDate = outcome.values.last?.createdDate ?? event.scheduleEvent.start
            return outcome
        } else {
            var newOutcome = OCKOutcome(
                taskUUID: event.task.uuid,
                taskOccurrenceIndex: event.scheduleEvent.occurrence,
                values: values
            )
            newOutcome.effectiveDate = values.last?.createdDate ?? event.scheduleEvent.start
            return newOutcome
        }
    }

    private func randomDate(_ startDate: Date, end endDate: Date) -> Date {
        let range = startDate.timeIntervalSince1970..<endDate.timeIntervalSince1970
        return Date(timeIntervalSince1970: TimeInterval.random(in: range))
    }
}
