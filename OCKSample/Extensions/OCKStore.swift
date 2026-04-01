//
//  OCKStore.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import CareKitEssentials
import Contacts
import Foundation
import CareKitStore
import os.log
import ResearchKitSwiftUI

extension OCKStore {
    @MainActor
    class func getCarePlanUUIDs() async throws -> [CarePlanID: UUID] {
        var results = [CarePlanID: UUID]()

        guard let store = AppDelegateKey.defaultValue?.store else {
            return results
        }

        var query = OCKCarePlanQuery(for: Date())
        query.ids = [
            CarePlanID.health.rawValue
        ]

        let foundCarePlans = try await store.fetchCarePlans(query: query)
        // Populate the dictionary for all CarePlan's
        CarePlanID.allCases.forEach { carePlanID in
            results[carePlanID] = foundCarePlans
                .first(where: { $0.id == carePlanID.rawValue })?.uuid
        }
        return results
    }
    // TODO: Rewrite this method in a functional programming way.
        /**
         Adds an `OCKAnyCarePlan`*asynchronously*  to `OCKStore` if it has not been added already.

         - parameter carePlans: The array of `OCKAnyCarePlan`'s to be added to the `OCKStore`.
         - parameter patientUUID: The uuid of the `OCKPatient` to tie to the `OCKCarePlan`. Defaults to nil.
         - throws: An error if there was a problem adding the missing `OCKAnyCarePlan`'s.
         - note: `OCKAnyCarePlan`'s that have an existing `id` will not be added and will not cause errors to be thrown.
        */
    func addCarePlansIfNotPresent(
        _ carePlans: [OCKAnyCarePlan],
        patientUUID: UUID? = nil
    ) async throws {
        let carePlanIdsToAdd = carePlans.compactMap { $0.id }

        // Prepare query to see if Care Plan are already added
        var query = OCKCarePlanQuery(for: Date())
        query.ids = carePlanIdsToAdd
        let foundCarePlans = try await self.fetchAnyCarePlans(query: query)
        var carePlanNotInStore = [OCKAnyCarePlan]()
        // Check results to see if there's a missing Care Plan
        carePlans.forEach { potentialCarePlan in
            if foundCarePlans.first(where: { $0.id == potentialCarePlan.id }) == nil {
                // Check if can be casted to OCKCarePlan to add patientUUID
                guard var mutableCarePlan = potentialCarePlan as? OCKCarePlan else {
                    carePlanNotInStore.append(potentialCarePlan)
                    return
                }
                mutableCarePlan.patientUUID = patientUUID
                carePlanNotInStore.append(mutableCarePlan)
            }
        }

        // Only add if there's a new Care Plan
        if carePlanNotInStore.count > 0 {
            do {
                _ = try await self.addAnyCarePlans(carePlanNotInStore)
                Logger.ockStore.info("Added Care Plans into OCKStore!")
            } catch {
                Logger.ockStore.error("Error adding Care Plans: \(error.localizedDescription)")
            }
        }
    }

    // TODO: Rewrite this method in a functional programming way.
    func addTasksIfNotPresent(_ tasks: [OCKTask]) async throws -> [OCKTask] {
        let ids = tasks.map { $0.id }
        var query = OCKTaskQuery(for: Date())
        query.ids = ids
        let existing = try await fetchTasks(query: query)
        let existingIDs = Set(existing.map { $0.id })
        let missing = tasks.filter { !existingIDs.contains($0.id) }
        guard !missing.isEmpty else { return [] }
        return try await addTasks(missing)
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
    
    func populateCarePlans(patientUUID: UUID? = nil) async throws {
            // TODO: Add at least 2 more CarePlans.
            let healthCarePlan = OCKCarePlan(
                id: CarePlanID.health.rawValue,
                title: "Health Care Plan",
                patientUUID: patientUUID
            )
            try await addCarePlansIfNotPresent(
                [healthCarePlan],
                patientUUID: patientUUID
            )
        }
    
    /// Seeds the store with BioMesh default tasks and contacts on first sign-up.
    func populateDefaultCarePlansTasksContacts(_ patientUUID: UUID? = nil, startDate: Date = Date()) async throws {
        
        try await populateCarePlans(patientUUID: patientUUID)
        
        // TODO: Relate all tasks to a respective CarePlan
        let carePlanUUIDs = try await Self.getCarePlanUUIDs()
        
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
        caffeine.card = .button
        caffeine.priority = 0
        caffeine.impactsAdherence = false

        _ = try await addOnboardingTask(carePlanUUIDs[.health])
        _ = try await addUIKitSurveyTasks(carePlanUUIDs[.health])
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
        water.card = .button
        water.priority = 1
        water.impactsAdherence = false

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
        anxiety.card = .button
        anxiety.priority = 2
        anxiety.impactsAdherence = false

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
        windDown.card = .custom
        windDown.priority = 3
        windDown.impactsAdherence = true

        let qualityOfLife = createQualityOfLifeSurveyTask(carePlanUUID: nil)

        // Onboarding — one-time, all-day
        var onboarding = OCKTask(
            id: TaskID.onboarding,
            title: "Onboarding",
            carePlanUUID: nil,
            schedule: OCKSchedule.dailyAtTime(
                hour: 0, minutes: 0,
                start: morning, end: nil,
                text: "Complete enrollment",
                duration: .allDay,
                targetValues: []
            )
        )
        onboarding.instructions = "Complete the onboarding to enroll in the BioMesh study."
        onboarding.impactsAdherence = false
        onboarding.priority = -1
        onboarding.card = .instruction

        // Range of Motion — weekly
        var romTask = OCKTask(
            id: TaskID.rangeOfMotion,
            title: "Range of Motion",
            carePlanUUID: nil,
            schedule: OCKSchedule(composing: [
                OCKScheduleElement(
                    start: morning,
                    end: nil,
                    interval: DateComponents(weekOfYear: 1),
                    text: "Measure knee ROM",
                    targetValues: [],
                    duration: .allDay
                )
            ])
        )
        romTask.instructions = "Measure your left knee range of motion."
        romTask.impactsAdherence = true
        romTask.card = .instruction
        romTask.priority = 1

        _ = try await addTasksIfNotPresent([
            onboarding, romTask,
            caffeine, water, anxiety, windDown, qualityOfLife
        ])

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

    func createQualityOfLifeSurveyTask(carePlanUUID: UUID?) -> OCKTask {
        let qualityOfLifeTaskId = TaskID.qualityOfLife

        let thisMorning = Calendar.current.startOfDay(for: Date())
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
        let beforeBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: aFewDaysAgo)!
        let qualityOfLifeElement = OCKScheduleElement(
            start: beforeBreakfast, end: nil, interval: DateComponents(day: 1)
        )
        let qualityOfLifeSchedule = OCKSchedule(composing: [qualityOfLifeElement])

        let choices: [TextChoice] = [
            .init(id: "\(qualityOfLifeTaskId)_0", choiceText: "Yes", value: "Yes"),
            .init(id: "\(qualityOfLifeTaskId)_1", choiceText: "No", value: "No")
        ]

        let questionOne = SurveyQuestion(
            id: "\(qualityOfLifeTaskId)-managing-time",
            type: .multipleChoice,
            required: true,
            title: String(localized: "QUALITY_OF_LIFE_TIME"),
            textChoices: choices,
            choiceSelectionLimit: .single
        )

        let questionTwo = SurveyQuestion(
            id: qualityOfLifeTaskId,
            type: .slider,
            required: false,
            title: String(localized: "QUALITY_OF_LIFE_STRESS"),
            detail: String(localized: "QUALITY_OF_LIFE_STRESS_DETAIL"),
            integerRange: 0...10,
            sliderStepValue: 1
        )

        let stepOne = SurveyStep(
            id: "\(qualityOfLifeTaskId)-step-1",
            questions: [questionOne, questionTwo]
        )

        var qualityOfLife = OCKTask(
            id: "\(qualityOfLifeTaskId)-stress",
            title: String(localized: "QUALITY_OF_LIFE"),
            carePlanUUID: carePlanUUID,
            schedule: qualityOfLifeSchedule
        )
        qualityOfLife.instructions = "Answer a few quick questions about your stress and time management since using BioMesh."
        qualityOfLife.impactsAdherence = true
        qualityOfLife.asset = "list.clipboard"
        qualityOfLife.card = .survey
        qualityOfLife.surveySteps = [stepOne]
        qualityOfLife.priority = 1

        return qualityOfLife
    }
    func addOnboardingTask(_ carePlanUUID: UUID? = nil) async throws -> [OCKTask] {

            let onboardSchedule = OCKSchedule.dailyAtTime(
                hour: 0, minutes: 0,
                start: Date(), end: nil,
                text: "Task Due!",
                duration: .allDay
            )

            var onboardTask = OCKTask(
                id: Onboard.identifier(),
                title: "Onboard",
                carePlanUUID: carePlanUUID,
                schedule: onboardSchedule
            )
            onboardTask.instructions = "You'll need to agree to some terms and conditions before we get started!"
            onboardTask.impactsAdherence = false
            onboardTask.card = .uiKitSurvey
            onboardTask.uiKitSurvey = .onboard

            return try await addTasksIfNotPresent([onboardTask])
        }

    func addUIKitSurveyTasks(_ carePlanUUID: UUID? = nil) async throws -> [OCKTask] {
        let thisMorning = Calendar.current.startOfDay(for: Date())

        let nextWeek = Calendar.current.date(
            byAdding: .weekOfYear,
            value: 1,
            to: Date()
        )!

        let nextMonth = Calendar.current.date(
            byAdding: .month,
            value: 1,
            to: thisMorning
        )

        let dailyElement = OCKScheduleElement(
            start: thisMorning,
            end: nextWeek,
            interval: DateComponents(day: 1),
            text: nil,
            targetValues: [],
            duration: .allDay
        )

        let weeklyElement = OCKScheduleElement(
            start: nextWeek,
            end: nextMonth,
            interval: DateComponents(weekOfYear: 1),
            text: nil,
            targetValues: [],
            duration: .allDay
        )

        let rangeOfMotionCheckSchedule = OCKSchedule(
            composing: [dailyElement, weeklyElement]
        )

        var rangeOfMotionTask = OCKTask(
            id: RangeOfMotion.identifier(),
            title: "Range Of Motion",
            carePlanUUID: carePlanUUID,
            schedule: rangeOfMotionCheckSchedule
        )
        rangeOfMotionTask.priority = 2
        rangeOfMotionTask.asset = "figure.walk.motion"
        rangeOfMotionTask.card = .uiKitSurvey
        rangeOfMotionTask.uiKitSurvey = .rangeOfMotion

        return try await addTasksIfNotPresent([rangeOfMotionTask])
    }
}
