//
//  OCKStore+Defaults.swift
//  OCKSample
//
//  Created by Alarik Damrow on 2/21/26.
//  Updated by You on 2/21/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
import Foundation
import CareKitStore
#if canImport(Contacts)
import Contacts
#endif
extension OCKStore {
    func populateDefaultCarePlansTasksContacts(startDate: Date = Date()) async throws {
        func addTasksIfMissing(_ tasks: [OCKTask]) async throws {
            let ids = tasks.map { $0.id }
            var q = OCKTaskQuery(for: startDate)
            q.ids = ids
            let existing = try await fetchTasks(query: q)
            let existingIDs = Set(existing.map { $0.id })
            let missing = tasks.filter { !existingIDs.contains($0.id) }
            if !missing.isEmpty {
                _ = try await addTasks(missing)
            }
        }
        func addContactsIfMissing(_ contacts: [OCKContact]) async throws {
            let ids = contacts.map { $0.id }
            var q = OCKContactQuery(for: startDate)
            q.ids = ids
            let existing = try await fetchContacts(query: q)
            let existingIDs = Set(existing.map { $0.id })
            let missing = contacts.filter { !existingIDs.contains($0.id) }
            if !missing.isEmpty {
                _ = try await addContacts(missing)
            }
        }
        let calendar = Calendar.current
        let thisMorning = calendar.startOfDay(for: startDate)
        let allDayDaily = OCKSchedule(
            composing: [
                OCKScheduleElement(
                    start: thisMorning,
                    end: nil,
                    interval: DateComponents(day: 1),
                    text: "Any time today",
                    targetValues: [],
                    duration: .allDay
                )
            ]
        )
        let morningTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: thisMorning) ?? thisMorning
        let eveningTime = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: thisMorning) ?? thisMorning
        let dailyMorning = OCKSchedule(
            composing: [OCKScheduleElement(start: morningTime, end: nil, interval: DateComponents(day: 1))]
        )
        let dailyEvening = OCKSchedule(
            composing: [OCKScheduleElement(start: eveningTime, end: nil, interval: DateComponents(day: 1))]
        )
        var water = OCKTask(
            id: TaskID.waterIntake,
            title: "Water Intake",
            carePlanUUID: nil,
            schedule: allDayDaily
        )
        water.instructions = "Tap Log each time you drink a glass of water."
        water.asset = "drop.fill"
        water.tags = ["cardType:buttonLog"]
        water.impactsAdherence = false
        var caffeine = OCKTask(
            id: TaskID.caffeineIntake,
            title: "Caffeine Intake",
            carePlanUUID: nil,
            schedule: allDayDaily
        )
        caffeine.instructions = "Tap Log when you have coffee/tea/energy drinks."
        caffeine.asset = "cup.and.saucer.fill"
        caffeine.tags = ["cardType:buttonLog"]
        caffeine.impactsAdherence = false
        var steps = OCKTask(
            id: TaskID.steps,
            title: "Move Your Body",
            carePlanUUID: nil,
            schedule: allDayDaily
        )
        steps.instructions = "Aim for your daily step goal. Log progress when you’re ready."
        steps.asset = "figure.walk"
        steps.tags = ["cardType:numericProgress"]
        var mindfulness = OCKTask(
            id: TaskID.mindfulness,
            title: "Mindfulness Check-in",
            carePlanUUID: nil,
            schedule: dailyEvening
        )
        mindfulness.instructions = "Take 1 minute to breathe. Tap when completed."
        mindfulness.asset = "brain.head.profile"
        mindfulness.tags = ["cardType:buttonLog"]
        var resource = OCKTask(
            id: TaskID.resourceOfTheDay,
            title: "Resource of the Day",
            carePlanUUID: nil,
            schedule: dailyMorning
        )
        resource.instructions = """
Tip: Try the 4–7–8 breathing method.

Steps:
1) Inhale for 4 seconds
2) Hold for 7 seconds
3) Exhale for 8 seconds
Repeat 4 times.
"""
        resource.asset = "link"
        resource.tags = ["cardType:linkView"]
        try await addTasksIfMissing([water, caffeine, steps, mindfulness, resource])
        var support = OCKContact(
            id: "support",
            givenName: "App",
            familyName: "Support",
            carePlanUUID: nil
        )
        support.title = "Support"
        support.role = "Help with account, syncing, and troubleshooting."
        var coach = OCKContact(
            id: "coach",
            givenName: "Wellness",
            familyName: "Coach",
            carePlanUUID: nil
        )
        coach.title = "Coach"
        coach.role = "Guidance for building habits and staying consistent."
        #if canImport(Contacts)
        support.emailAddresses = [OCKLabeledValue(label: CNLabelWork, value: "support@yourapp.com")]
        support.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(555) 010-0001")]
        coach.emailAddresses = [OCKLabeledValue(label: CNLabelWork, value: "coach@yourapp.com")]
        coach.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(555) 010-0002")]
        #else
        // watchOS-safe labels (no Contacts framework)
        support.emailAddresses = [OCKLabeledValue(label: "work", value: "support@yourapp.com")]
        support.phoneNumbers = [OCKLabeledValue(label: "work", value: "(555) 010-0001")]

        coach.emailAddresses = [OCKLabeledValue(label: "work", value: "coach@yourapp.com")]
        coach.phoneNumbers = [OCKLabeledValue(label: "work", value: "(555) 010-0002")]
        #endif
        try await addContactsIfMissing([support, coach])
    }
}
