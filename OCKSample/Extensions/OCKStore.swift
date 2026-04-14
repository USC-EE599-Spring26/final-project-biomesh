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

    #if os(iOS)
    @MainActor
    class func getCarePlanUUIDs() async throws -> [CarePlanID: UUID] {
        var results = [CarePlanID: UUID]()

        guard let store = AppDelegateKey.defaultValue?.store else {
            return results
        }

        var query = OCKCarePlanQuery(for: Date())
        query.ids = CarePlanID.allCases.map { $0.rawValue }

        let foundCarePlans = try await store.fetchCarePlans(query: query)
        CarePlanID.allCases.forEach { carePlanID in
            results[carePlanID] = foundCarePlans
                .first(where: { $0.id == carePlanID.rawValue })?.uuid
        }
        return results
    }

    func addCarePlansIfNotPresent(
        _ carePlans: [OCKCarePlan],
        patientUUID: UUID? = nil
    ) async throws {
        let ids = carePlans.map { $0.id }
        var query = OCKCarePlanQuery(for: Date())
        query.ids = ids
        let existing = try await fetchCarePlans(query: query)
        let existingIDs = Set(existing.map { $0.id })
        let missing = carePlans
            .filter { !existingIDs.contains($0.id) }
            .map { plan -> OCKCarePlan in
                var mutable = plan
                mutable.patientUUID = patientUUID
                return mutable
            }
        guard !missing.isEmpty else { return }
        _ = try await addCarePlans(missing)
    }

    func populateCarePlans(patientUUID: UUID? = nil) async throws {
        let dailyTracking = OCKCarePlan(
            id: CarePlanID.dailyTracking.rawValue,
            title: "Daily Tracking",
            patientUUID: patientUUID
        )
        let sleepWellness = OCKCarePlan(
            id: CarePlanID.sleepWellness.rawValue,
            title: "Sleep & Wellness",
            patientUUID: patientUUID
        )
        let assessment = OCKCarePlan(
            id: CarePlanID.assessment.rawValue,
            title: "Assessments",
            patientUUID: patientUUID
        )
        try await addCarePlansIfNotPresent(
            [dailyTracking, sleepWellness, assessment],
            patientUUID: patientUUID
        )
    }
    #endif

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

    // swiftlint:disable:next function_body_length
    /// Seeds the store with BioMesh default tasks and contacts on first sign-up.
    func populateDefaultCarePlansTasksContacts(startDate: Date = Date()) async throws {

        #if os(iOS)
        try await populateCarePlans()
        let carePlanUUIDs = try await Self.getCarePlanUUIDs()
        let dailyTrackingUUID = carePlanUUIDs[.dailyTracking]
        let sleepWellnessUUID = carePlanUUIDs[.sleepWellness]
        let assessmentUUID = carePlanUUIDs[.assessment]
        #else
        let dailyTrackingUUID: UUID? = nil
        let sleepWellnessUUID: UUID? = nil
        let assessmentUUID: UUID? = nil
        #endif

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
            bySettingHour: 21, minute: 30, second: 0, of: morning
        ) ?? morning
        let eveningSchedule = OCKSchedule(composing: [
            OCKScheduleElement(
                start: eveningStart,
                end: nil,
                interval: DateComponents(day: 1)
            )
        ])
        let hydrationSchedule = OCKSchedule(composing: [
            OCKScheduleElement(
                start: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: morning) ?? morning,
                end: nil,
                interval: DateComponents(day: 1),
                text: "Late morning",
                targetValues: [],
                duration: .allDay
            ),
            OCKScheduleElement(
                start: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: morning) ?? morning,
                end: nil,
                interval: DateComponents(day: 1),
                text: "Late afternoon",
                targetValues: [],
                duration: .allDay
            )
        ])
        let morningReflectionSchedule = OCKSchedule(composing: [
            OCKScheduleElement(
                start: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: morning) ?? morning,
                end: nil,
                interval: DateComponents(day: 1),
                text: "Morning check-in",
                targetValues: [],
                duration: .allDay
            )
        ])
        let middaySchedule = OCKSchedule(composing: [
            OCKScheduleElement(
                start: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: morning) ?? morning,
                end: nil,
                interval: DateComponents(day: 1),
                text: "Midday",
                targetValues: [],
                duration: .allDay
            )
        ])
        let afternoonSchedule = OCKSchedule(composing: [
            OCKScheduleElement(
                start: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: morning) ?? morning,
                end: nil,
                interval: DateComponents(day: 1),
                text: "Afternoon",
                targetValues: [],
                duration: .allDay
            )
        ])

        // Caffeine Intake
        // Logs each caffeinated drink throughout the day.
        // Research note: >400 mg/day linked to significantly higher anxiety risk.
        var caffeine = OCKTask(
            id: TaskID.caffeineIntake,
            title: "Caffeine Intake",
            carePlanUUID: dailyTrackingUUID,
            schedule: allDay
        )
        caffeine.instructions = "Tap Log each time you have a caffeinated drink " +
            "(coffee, tea, energy drink). Note: >400 mg/day is linked to higher anxiety risk."
        caffeine.asset = "cup.and.saucer.fill"
        caffeine.card = .button
        caffeine.priority = 0
        caffeine.impactsAdherence = false

        // Water Intake
        // Tracks hydration as a control variable.
        var water = OCKTask(
            id: TaskID.waterIntake,
            title: "Hydration Checkpoint",
            carePlanUUID: dailyTrackingUUID,
            schedule: hydrationSchedule
        )
        water.instructions = "Check in around late morning and late afternoon to confirm " +
            "you had water. Hydration helps separate caffeine effects from simple dehydration."
        water.asset = "drop.fill"
        water.card = .button
        water.priority = 1
        water.impactsAdherence = false

        // Anxiety Check-in
        // Captures the primary outcome variable from the research model.
        let anxietySchedule = OCKSchedule(composing: [
            OCKScheduleElement(
                start: morning,
                end: nil,
                interval: DateComponents(day: 2),
                text: "Every other day",
                targetValues: [],
                duration: .allDay
            )
        ])

        var anxiety = OCKTask(
            id: TaskID.anxietyCheck,
            title: "Anxiety Check-in",
            carePlanUUID: dailyTrackingUUID,
            schedule: anxietySchedule
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
            carePlanUUID: sleepWellnessUUID,
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

        var hydrationGuide = OCKTask(
            id: TaskID.hydrationGuide,
            title: "Hydration Guide",
            carePlanUUID: sleepWellnessUUID,
            schedule: morningReflectionSchedule
        )
        hydrationGuide.instructions = "Read a quick reminder about why hydration matters before your first caffeinated drink."
        hydrationGuide.asset = "drop.circle.fill"
        hydrationGuide.card = .instruction
        hydrationGuide.priority = 4
        hydrationGuide.impactsAdherence = false

        var energySnapshot = OCKTask(
            id: TaskID.energySnapshot,
            title: "Morning Energy Snapshot",
            carePlanUUID: dailyTrackingUUID,
            schedule: morningReflectionSchedule
        )
        energySnapshot.instructions = "Give yourself one quick tap to note whether you feel ready for the day before reaching for caffeine."
        energySnapshot.asset = "sun.max.fill"
        energySnapshot.card = .simple
        energySnapshot.priority = 5
        energySnapshot.impactsAdherence = false

        var stretchChecklist = OCKTask(
            id: TaskID.stretchChecklist,
            title: "Desk Stretch Break",
            carePlanUUID: sleepWellnessUUID,
            schedule: afternoonSchedule
        )
        stretchChecklist.instructions = "Use this checklist to pause, reset posture, and reduce tension during the afternoon."
        stretchChecklist.asset = "figure.cooldown"
        stretchChecklist.card = .checklist
        stretchChecklist.priority = 6
        stretchChecklist.impactsAdherence = true

        var studyResource = OCKTask(
            id: TaskID.studyResource,
            title: "Caffeine Research Resource",
            carePlanUUID: assessmentUUID,
            schedule: middaySchedule
        )
        studyResource.instructions = "Open this resource for a short explainer on caffeine timing, hydration, and recovery habits."
        studyResource.asset = "link.circle.fill"
        studyResource.card = .link
        studyResource.externalURL = URL(string: "https://www.cdc.gov/sleep/about_sleep/sleep_hygiene.html")
        studyResource.priority = 7
        studyResource.impactsAdherence = false

        let weeklyReflection = createQualityOfLifeSurveyTask(carePlanUUID: assessmentUUID)

        _ = try await addTasksIfNotPresent([
            caffeine,
            water,
            anxiety,
            windDown,
            hydrationGuide,
            energySnapshot,
            stretchChecklist,
            studyResource,
            weeklyReflection
        ])

        #if os(iOS)
        _ = try await addOnboardingTask(assessmentUUID)
        _ = try await addUIKitSurveyTasks(assessmentUUID)
        #endif

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
        let weeklyReflectionTaskID = TaskID.weeklyReflection
        let calendar = Calendar.current
        let now = Date()
        let sundayEvening = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 18, minute: 0, second: 0, weekday: 1),
            matchingPolicy: .nextTime,
            direction: .forward
        ) ?? now
        let reflectionElement = OCKScheduleElement(
            start: sundayEvening,
            end: nil,
            interval: DateComponents(weekOfYear: 1),
            text: "Every Sunday evening",
            targetValues: [],
            duration: .allDay
        )
        let qualityOfLifeSchedule = OCKSchedule(composing: [reflectionElement])

        let choices: [TextChoice] = [
            .init(id: "\(weeklyReflectionTaskID)_0", choiceText: "Yes", value: "Yes"),
            .init(id: "\(weeklyReflectionTaskID)_1", choiceText: "No", value: "No")
        ]

        let questionOne = SurveyQuestion(
            id: "\(weeklyReflectionTaskID)-caffeine-cutoff",
            type: .multipleChoice,
            required: true,
            title: "Did you stop caffeine by 2 PM on most days this week?",
            textChoices: choices,
            choiceSelectionLimit: .single
        )

        let questionTwo = SurveyQuestion(
            id: "\(weeklyReflectionTaskID)-stress",
            type: .slider,
            required: false,
            title: "How manageable did your stress feel this week?",
            detail: "0 means not manageable at all, and 10 means very manageable.",
            integerRange: 0...10,
            sliderStepValue: 1
        )
        let questions = [questionOne, questionTwo]
        let taskAsset = "calendar.badge.clock"
        let taskTitle = "Weekly Pattern Reflection"
        let stepOne = SurveyStep(
            id: "\(weeklyReflectionTaskID)-step-1",
            questions: questions,
            asset: taskAsset,
            title: taskTitle,
            subtitle: "Think about your last 7 days and answer honestly."
        )

        var qualityOfLife = OCKTask(
            id: weeklyReflectionTaskID,
            title: taskTitle,
            carePlanUUID: carePlanUUID,
            schedule: qualityOfLifeSchedule
        )
        qualityOfLife.instructions = "Reflect once a week on your caffeine cutoff and how manageable your stress felt."
        qualityOfLife.impactsAdherence = true
        qualityOfLife.asset = "list.clipboard"
        qualityOfLife.card = CareKitCard.survey
        qualityOfLife.surveySteps = [stepOne]
        qualityOfLife.priority = 4

        return qualityOfLife
    }

    #if os(iOS)
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
            byAdding: .weekOfYear, value: 1, to: Date()
        )!
        let nextMonth = Calendar.current.date(
            byAdding: .month, value: 1, to: thisMorning
        )

        let dailyElement = OCKScheduleElement(
            start: thisMorning, end: nextWeek,
            interval: DateComponents(day: 1),
            text: nil, targetValues: [], duration: .allDay
        )
        let weeklyElement = OCKScheduleElement(
            start: nextWeek, end: nextMonth,
            interval: DateComponents(weekOfYear: 1),
            text: nil, targetValues: [], duration: .allDay
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
    #endif
}
