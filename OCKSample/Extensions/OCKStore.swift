//
//  OCKStore.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

//
//  OCKStore.swift
//  OCKSample
//
// swiftlint:disable line_length

import Contacts
import Foundation
import CareKitStore
import os.log
import ResearchKitSwiftUI

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

        // Caffeine Intake
        var caffeine = OCKTask(
            id: TaskID.caffeineIntake,
            title: "Caffeine Intake",
            carePlanUUID: nil,
            schedule: allDay
        )
        caffeine.instructions = "Tap Log each time you have a caffeinated drink (coffee, tea, energy drink). Note: >400 mg/day is linked to higher anxiety risk."
        caffeine.asset = "cup.and.saucer.fill"
        caffeine.impactsAdherence = false
        caffeine.card = .button
        caffeine.priority = 2

        // Water Intake
        var water = OCKTask(
            id: TaskID.waterIntake,
            title: "Water Intake",
            carePlanUUID: nil,
            schedule: allDay
        )
        water.instructions = "Tap Log each time you drink a glass of water. Staying hydrated helps separate caffeine effects from dehydration."
        water.asset = "drop.fill"
        water.impactsAdherence = false
        water.card = .button
        water.priority = 3

        // Anxiety Check-in
        var anxiety = OCKTask(
            id: TaskID.anxietyCheck,
            title: "Anxiety Check-in",
            carePlanUUID: nil,
            schedule: allDay
        )
        anxiety.instructions = "Tap Log whenever you notice an anxiety episode. Try to note how long ago you last had caffeine — this helps trace the caffeine → anxiety relationship your app is studying."
        anxiety.asset = "brain.head.profile"
        anxiety.impactsAdherence = false
        anxiety.card = .button
        anxiety.priority = 0

        // Evening Wind-Down
        var windDown = OCKTask(
            id: TaskID.sleepHygiene,
            title: "Evening Wind-Down",
            carePlanUUID: nil,
            schedule: eveningSchedule
        )
        windDown.instructions = "Complete your wind-down routine before bed:\n• No caffeine after 2 PM\n• Dim lights 30 min before sleep\n• Put your phone face-down\nGood sleep quality is the mediator between caffeine and next-day anxiety."
        windDown.asset = "moon.zzz.fill"
        windDown.impactsAdherence = true
        windDown.card = .checklist
        windDown.priority = 1

        let qualityOfLife = createQualityOfLifeSurveyTask(carePlanUUID: nil)
        let checkIn = createCheckInSurveyTask(carePlanUUID: nil, startDate: startDate)
        let rangeOfMotion = createRangeOfMotionSurveyTask(carePlanUUID: nil, startDate: startDate)

        _ = try await addOrUpdateTasks([
            caffeine,
            water,
            anxiety,
            windDown,
            qualityOfLife,
            checkIn,
            rangeOfMotion
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

        let textChoiceYesText = String(localized: "ANSWER_YES")
        let textChoiceNoText = String(localized: "ANSWER_NO")
        let yesValue = "Yes"
        let noValue = "No"

        let choices: [TextChoice] = [
            .init(
                id: "\(qualityOfLifeTaskId)_0",
                choiceText: textChoiceYesText,
                value: yesValue
            ),
            .init(
                id: "\(qualityOfLifeTaskId)_1",
                choiceText: textChoiceNoText,
                value: noValue
            )
        ]

        let questionOne = SurveyQuestion(
            id: "\(qualityOfLifeTaskId)-managing-time",
            type: .multipleChoice,
            required: true,
            title: String(localized: "QUALITY_OF_LIFE_TIME"),
            textChoices: choices,
            choicesSelectionLimit: .single
        )

        let questionTwo = SurveyQuestion(
            id: "\(qualityOfLifeTaskId)-stress",
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
            id: qualityOfLifeTaskId,
            title: String(localized: "QUALITY_OF_LIFE"),
            carePlanUUID: carePlanUUID,
            schedule: qualityOfLifeSchedule
        )

        qualityOfLife.instructions = String(localized: "QUALITY_OF_LIFE_INSTRUCTIONS")
        qualityOfLife.impactsAdherence = true
        qualityOfLife.asset = "brain.head.profile"
        qualityOfLife.card = .survey
        qualityOfLife.surveySteps = [stepOne]
        qualityOfLife.priority = 1

        return qualityOfLife
    }

    func createCheckInSurveyTask(
        carePlanUUID: UUID?,
        startDate: Date = Date()
    ) -> OCKTask {

        let taskID = TaskID.checkIn

        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(
                start: Calendar.current.startOfDay(for: startDate),
                end: nil,
                interval: DateComponents(day: 1),
                text: "Complete once today",
                targetValues: [],
                duration: .allDay
            )
        ])

        let moodChoices: [TextChoice] = [
            .init(id: "\(taskID).mood.great", choiceText: "Great", value: "Great"),
            .init(id: "\(taskID).mood.okay", choiceText: "Okay", value: "Okay"),
            .init(id: "\(taskID).mood.bad", choiceText: "Bad", value: "Bad")
        ]

        let yesNoChoices: [TextChoice] = [
            .init(id: "\(taskID).yes", choiceText: "Yes", value: "Yes"),
            .init(id: "\(taskID).no", choiceText: "No", value: "No")
        ]

        let moodQuestion = SurveyQuestion(
            id: "\(taskID).mood",
            type: .multipleChoice,
            required: true,
            title: "How do you feel today?",
            detail: "Choose the option that best matches your overall mood.",
            textChoices: moodChoices,
            choicesSelectionLimit: .single,
            integerRange: nil,
            sliderStepValue: nil
        )

        let stressQuestion = SurveyQuestion(
            id: "\(taskID).stress",
            type: .slider,
            required: true,
            title: "How stressed do you feel right now?",
            detail: "0 = no stress, 10 = highest stress",
            textChoices: nil,
            choicesSelectionLimit: nil,
            integerRange: 0...10,
            sliderStepValue: 1
        )

        let sleepQuestion = SurveyQuestion(
            id: "\(taskID).sleep",
            type: .slider,
            required: false,
            title: "How well did you sleep last night?",
            detail: "0 = very poorly, 10 = extremely well",
            textChoices: nil,
            choicesSelectionLimit: nil,
            integerRange: 0...10,
            sliderStepValue: 1
        )

        let symptomsQuestion = SurveyQuestion(
            id: "\(taskID).symptoms",
            type: .multipleChoice,
            required: true,
            title: "Are you having symptoms today?",
            detail: "Select the best answer.",
            textChoices: yesNoChoices,
            choicesSelectionLimit: .single,
            integerRange: nil,
            sliderStepValue: nil
        )

        let checkInStep = SurveyStep(
            id: "\(taskID).step.1",
            questions: [
                moodQuestion,
                stressQuestion,
                sleepQuestion,
                symptomsQuestion
            ]
        )

        var task = OCKTask(
            id: taskID,
            title: "Daily Check-In",
            carePlanUUID: carePlanUUID,
            schedule: schedule
        )

        task.instructions = "Complete this short daily check-in to track your mood, stress, sleep, and symptoms over time."
        task.asset = "checkmark.bubble.fill"
        task.impactsAdherence = true
        task.card = .survey
        task.surveySteps = [checkInStep]
        task.priority = 1

        return task
    }

    func createRangeOfMotionSurveyTask(
        carePlanUUID: UUID?,
        startDate: Date = Date()
    ) -> OCKTask {

        let taskID = TaskID.rangeOfMotion

        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(
                start: Calendar.current.startOfDay(for: startDate),
                end: nil,
                interval: DateComponents(day: 1),
                text: "Complete once today",
                targetValues: [],
                duration: .allDay
            )
        ])

        let shoulderQuestion = SurveyQuestion(
            id: "\(taskID).shoulder",
            type: .slider,
            required: true,
            title: "How far can you raise your arm today?",
            detail: "0 = cannot raise at all, 10 = full range of motion",
            textChoices: nil,
            choicesSelectionLimit: nil,
            integerRange: 0...10,
            sliderStepValue: 1
        )

        let neckQuestion = SurveyQuestion(
            id: "\(taskID).neck",
            type: .slider,
            required: false,
            title: "How easily can you turn your neck today?",
            detail: "0 = not at all, 10 = full motion",
            textChoices: nil,
            choicesSelectionLimit: nil,
            integerRange: 0...10,
            sliderStepValue: 1
        )

        let kneeQuestion = SurveyQuestion(
            id: "\(taskID).knee",
            type: .slider,
            required: false,
            title: "How well can you bend your knee today?",
            detail: "0 = no movement, 10 = full movement",
            textChoices: nil,
            choicesSelectionLimit: nil,
            integerRange: 0...10,
            sliderStepValue: 1
        )

        let painQuestion = SurveyQuestion(
            id: "\(taskID).pain",
            type: .slider,
            required: false,
            title: "How much pain do you feel during movement?",
            detail: "0 = no pain, 10 = worst pain",
            textChoices: nil,
            choicesSelectionLimit: nil,
            integerRange: 0...10,
            sliderStepValue: 1
        )

        let rangeOfMotionStep = SurveyStep(
            id: "\(taskID).step.1",
            questions: [
                shoulderQuestion,
                neckQuestion,
                kneeQuestion,
                painQuestion
            ]
        )

        var task = OCKTask(
            id: taskID,
            title: "Range of Motion",
            carePlanUUID: carePlanUUID,
            schedule: schedule
        )

        task.instructions = "Track your daily movement and comfort during motion. Use the sliders to estimate how well you can move today."
        task.asset = "figure.flexibility"
        task.impactsAdherence = true
        task.card = .survey
        task.surveySteps = [rangeOfMotionStep]
        task.priority = 2

        return task
    }
}
