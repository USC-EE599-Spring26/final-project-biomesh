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
#if canImport(ResearchKitSwiftUI)
import ResearchKitSwiftUI
#endif

extension OCKStore {

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

    func addCarePlansIfNotPresent(_ carePlans: [OCKCarePlan]) async throws -> [OCKCarePlan] {
        let ids = carePlans.map { $0.id }
        var query = OCKCarePlanQuery(for: Date())
        query.ids = ids
        let existing = try await fetchCarePlans(query: query)
        let existingIDs = Set(existing.map { $0.id })
        let missing = carePlans.filter { !existingIDs.contains($0.id) }
        guard !missing.isEmpty else { return [] }
        return try await addCarePlans(missing)
    }

    func populateDefaultCarePlans(patientUUID: UUID? = nil) async throws -> [CarePlanID: UUID] {
        let carePlans: [OCKCarePlan] = [
            OCKCarePlan(
                id: CarePlanID.health.rawValue,
                title: "Health",
                patientUUID: patientUUID
            ),
            OCKCarePlan(
                id: CarePlanID.wellness.rawValue,
                title: "Wellness",
                patientUUID: patientUUID
            ),
            OCKCarePlan(
                id: CarePlanID.nutrition.rawValue,
                title: "Nutrition",
                patientUUID: patientUUID
            ),
            OCKCarePlan(
                id: CarePlanID.study.rawValue,
                title: "Study",
                patientUUID: patientUUID
            ),
            OCKCarePlan(
                id: CarePlanID.recovery.rawValue,
                title: "Recovery",
                patientUUID: patientUUID
            )
        ]

        _ = try await addCarePlansIfNotPresent(carePlans)

        var query = OCKCarePlanQuery(for: Date())
        query.ids = CarePlanID.allCases.map(\.rawValue)

        let savedPlans = try await fetchCarePlans(query: query)

        var uuids = [CarePlanID: UUID]()
        for type in CarePlanID.allCases {
            if let uuid = savedPlans.first(where: { $0.id == type.rawValue })?.uuid {
                uuids[type] = uuid
            }
        }

        return uuids
    }

    /// Seeds the store with BioMesh default care plans, tasks, and contacts on first sign-up.
    func populateDefaultCarePlansTasksContacts(
        patientUUID: UUID? = nil,
        startDate: Date = Date()
    ) async throws {

        let carePlanUUIDs = try await populateDefaultCarePlans(patientUUID: patientUUID)
        _ = carePlanUUIDs[.health]
        let wellnessUUID = carePlanUUIDs[.wellness]
        let nutritionUUID = carePlanUUIDs[.nutrition]
        let studyUUID = carePlanUUIDs[.study]
        let recoveryUUID = carePlanUUIDs[.recovery]
        

        let calendar = Calendar.current
        let morning = calendar.startOfDay(for: startDate)

        let allDay = OCKSchedule(composing: [
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
            bySettingHour: 21,
            minute: 0,
            second: 0,
            of: morning
        ) ?? morning

        let eveningSchedule = OCKSchedule(composing: [
            OCKScheduleElement(
                start: eveningStart,
                end: nil,
                interval: DateComponents(day: 1)
            )
        ])

        // Nutrition
        var caffeine = OCKTask(
            id: TaskID.caffeineIntake,
            title: "Caffeine Intake",
            carePlanUUID: nutritionUUID,
            schedule: allDay
        )
        caffeine.instructions = """
        Task ID: \(caffeine.id)

        Tap Log each time you have a caffeinated drink (coffee, tea, energy drink). Note: >400 mg/day is linked to higher anxiety risk.
        """
        caffeine.asset = "cup.and.saucer.fill"
        caffeine.card = .button
        caffeine.priority = 0
        caffeine.impactsAdherence = false

        var water = OCKTask(
            id: TaskID.waterIntake,
            title: "Water Intake",
            carePlanUUID: nutritionUUID,
            schedule: allDay
        )
        water.instructions = """
        Task ID: \(water.id)

        Tap Log each time you drink a glass of water. Staying hydrated helps separate caffeine effects from dehydration.
        """
        water.asset = "drop.fill"
        water.card = .button
        water.priority = 1
        water.impactsAdherence = false

        // Wellness
        var anxiety = OCKTask(
            id: TaskID.anxietyCheck,
            title: "Anxiety Check-in",
            carePlanUUID: wellnessUUID,
            schedule: allDay
        )
        anxiety.instructions = """
        Task ID: \(anxiety.id)

        Tap Log whenever you notice an anxiety episode. Try to note how long ago you last had caffeine — this helps trace the caffeine → anxiety relationship your app is studying.
        """
        anxiety.asset = "brain.head.profile"
        anxiety.card = .button
        anxiety.priority = 2
        anxiety.impactsAdherence = false

        var windDown = OCKTask(
            id: TaskID.sleepHygiene,
            title: "Evening Wind-Down",
            carePlanUUID: wellnessUUID,
            schedule: eveningSchedule
        )
        windDown.instructions = """
        Task ID: \(windDown.id)

        Complete your wind-down routine before bed:
        • No caffeine after 2 PM
        • Dim lights 30 min before sleep
        • Put your phone face-down

        Good sleep quality is the mediator between caffeine and next-day anxiety.
        """
        windDown.asset = "moon.zzz.fill"
        windDown.card = .custom
        windDown.priority = 3
        windDown.impactsAdherence = true

        let qualityOfLife = createQualityOfLifeSurveyTask(carePlanUUID: wellnessUUID)

        // Health
        var onboarding = OCKTask(
            id: TaskID.onboarding,
            title: "Onboarding",
            carePlanUUID: studyUUID,
            schedule: OCKSchedule.dailyAtTime(
                hour: 0,
                minutes: 0,
                start: morning,
                end: nil,
                text: "Complete enrollment",
                duration: .allDay,
                targetValues: []
            )
        )
        onboarding.instructions = """
        Task ID: \(onboarding.id)

        Complete the onboarding to enroll in the BioMesh study.
        """
        onboarding.impactsAdherence = false
        onboarding.priority = -1
        #if os(iOS)
        onboarding.card = .uiKitSurvey
        onboarding.uiKitSurvey = .onboard
        #else
        onboarding.card = .instruction
        #endif

        var romTask = OCKTask(
            id: TaskID.rangeOfMotion,
            title: "Range of Motion",
            carePlanUUID: recoveryUUID,
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
        romTask.instructions = """
        Task ID: \(romTask.id)

        Measure your left knee range of motion.
        """
        romTask.impactsAdherence = true
        romTask.priority = 1
        #if os(iOS)
        romTask.card = .uiKitSurvey
        romTask.uiKitSurvey = .rangeOfMotion
        #else
        romTask.card = .instruction
        #endif

        _ = try await addTasksIfNotPresent([
            onboarding,
            romTask,
            caffeine,
            water,
            anxiety,
            windDown,
            qualityOfLife
        ])

        var researcher = OCKContact(
            id: "biomesh.researcher",
            givenName: "BioMesh",
            familyName: "Research Team",
            carePlanUUID: studyUUID
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
            carePlanUUID: wellnessUUID
        )
        advisor.title = "Wellness Advisor"
        advisor.role = "General guidance on managing caffeine intake, sleep hygiene, and anxiety reduction strategies."
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
            start: beforeBreakfast,
            end: nil,
            interval: DateComponents(day: 1)
        )
        let qualityOfLifeSchedule = OCKSchedule(composing: [qualityOfLifeElement])

        var qualityOfLife = OCKTask(
            id: "\(qualityOfLifeTaskId)-stress",
            title: String(localized: "QUALITY_OF_LIFE"),
            carePlanUUID: carePlanUUID,
            schedule: qualityOfLifeSchedule
        )
        qualityOfLife.instructions = """
        Task ID: \(qualityOfLife.id)

        Answer a few quick questions about your stress and time management since using BioMesh.
        """
        qualityOfLife.impactsAdherence = true
        qualityOfLife.asset = "list.clipboard"
        qualityOfLife.priority = 1

        #if canImport(ResearchKitSwiftUI)
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

        qualityOfLife.card = .survey
        qualityOfLife.surveySteps = [stepOne]
        #else
        qualityOfLife.card = .instruction
        #endif

        return qualityOfLife
    }
}
