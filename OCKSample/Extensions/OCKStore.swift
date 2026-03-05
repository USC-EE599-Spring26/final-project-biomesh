//
//  OCKStore.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Contacts
import Foundation
import CareKitStore
import os.log

extension OCKStore {

    func addOrUpdateTasks(_ tasks: [OCKTask]) async throws -> [OCKTask] {
        let ids = tasks.map { $0.id }

        var query = OCKTaskQuery(for: Date())
        query.ids = ids

        let existing = try await fetchTasks(query: query)
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        var addedOrUpdated: [OCKTask] = []

        for task in tasks {
            if var existingTask = existingByID[task.id] {
                existingTask.title = task.title
                existingTask.instructions = task.instructions
                existingTask.asset = task.asset
                existingTask.schedule = task.schedule
                existingTask.impactsAdherence = task.impactsAdherence
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

    func addContactsIfNotPresent(_ contacts: [OCKContact]) async throws -> [OCKContact] {
        let ids = contacts.map { $0.id }
        var query = OCKContactQuery(for: Date())
        query.ids = ids
        let existing = try await fetchContacts(query: query)
        let existingIDs = Set(existing.map { $0.id })
        let missing = contacts.filter { !existingIDs.contains($0.id) }
        guard !missing.isEmpty else { return [] }
        return try await addContacts(missing)
    }

    /// Seeds the store with BioMesh default tasks and contacts on first sign-up.
    func populateDefaultCarePlansTasksContacts(startDate: Date = Date()) async throws {

        let calendar  = Calendar.current
        let morning   = calendar.startOfDay(for: startDate)
        let allDay    = OCKSchedule(composing: [
            OCKScheduleElement(
                start: morning,
                end: nil,
                interval: DateComponents(day: 1),
                text: "Any time today",
                targetValues: [],
                duration: .allDay
            )
        ])
        let eveningStart = calendar.date(
            bySettingHour: 21, minute: 0, second: 0, of: morning
        ) ?? morning
        let eveningSchedule = OCKSchedule(composing: [
            OCKScheduleElement(
                start: eveningStart,
                end: nil,
                interval: DateComponents(day: 1)
            )
        ])

        // Caffeine Intake
        // Logs each caffeinated drink throughout the day.
        // Research note: >400 mg/day linked to significantly higher anxiety risk.
        var caffeine = OCKTask(
            id: TaskID.caffeineIntake,
            title: "Caffeine Intake",
            carePlanUUID: nil,
            schedule: allDay
        )
        caffeine.instructions = "Tap Log each time you have a caffeinated drink " +
            "(coffee, tea, energy drink). Note: >400 mg/day is linked to higher anxiety risk."
        caffeine.asset = "cup.and.saucer.fill"
        caffeine.impactsAdherence = false
        caffeine.card = .button
        caffeine.priority = 2

        // Water Intake
        // Tracks hydration as a control variable.
        var water = OCKTask(
            id: TaskID.waterIntake,
            title: "Water Intake",
            carePlanUUID: nil,
            schedule: allDay
        )
        water.instructions = "Tap Log each time you drink a glass of water. " +
            "Staying hydrated helps separate caffeine effects from dehydration."
        water.asset = "drop.fill"
        water.impactsAdherence = false
        water.card = .button
        water.priority = 3

        // Anxiety Check-in
        // Captures the primary outcome variable from the research model.
        var anxiety = OCKTask(
            id: TaskID.anxietyCheck,
            title: "Anxiety Check-in",
            carePlanUUID: nil,
            schedule: allDay
        )
        anxiety.instructions = "Tap Log whenever you notice an anxiety episode. " +
            "Try to note how long ago you last had caffeine — this helps trace the " +
            "caffeine → anxiety relationship your app is studying."
        anxiety.asset = "brain.head.profile"
        anxiety.impactsAdherence = false
        anxiety.card = .button
        anxiety.priority = 0

        // Evening Wind-Down
        // A checklist to support the sleep mediator variable.
        var windDown = OCKTask(
            id: TaskID.sleepHygiene,
            title: "Evening Wind-Down",
            carePlanUUID: nil,
            schedule: eveningSchedule
        )
        windDown.instructions = "Complete your wind-down routine before bed:\n" +
            "• No caffeine after 2 PM\n" +
            "• Dim lights 30 min before sleep\n" +
            "• Put your phone face-down\n" +
            "Good sleep quality is the mediator between caffeine and next-day anxiety."
        windDown.asset = "moon.zzz.fill"
        windDown.impactsAdherence = true
        windDown.card = .checklist
        windDown.priority = 1

        _ = try await addOrUpdateTasks([caffeine, water, anxiety, windDown])
        // Contacts
        var researcher = OCKContact(
            id: "biomesh.researcher",
            givenName: "BioMesh",
            familyName: "Research Team",
            carePlanUUID: nil
        )
        researcher.title = "Study Coordinator"
        researcher.role = "Contact us with questions about your data or the study protocol."
        researcher.emailAddresses = [
            OCKLabeledValue(label: CNLabelWork, value: "research@biomesh.health")
        ]
        researcher.phoneNumbers = [
            OCKLabeledValue(label: CNLabelWork, value: "(213) 555-0100")
        ]

        var advisor = OCKContact(
            id: "biomesh.advisor",
            givenName: "Health",
            familyName: "Advisor",
            carePlanUUID: nil
        )
        advisor.title = "Wellness Advisor"
        advisor.role = "General guidance on managing caffeine intake, sleep hygiene, " +
            "and anxiety reduction strategies."
        advisor.emailAddresses = [
            OCKLabeledValue(label: CNLabelWork, value: "advisor@biomesh.health")
        ]
        advisor.phoneNumbers = [
            OCKLabeledValue(label: CNLabelWork, value: "(213) 555-0200")
        ]

        _ = try await addContactsIfNotPresent([researcher, advisor])
    }
}
