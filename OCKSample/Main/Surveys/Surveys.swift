//
//  Surveys.swift
//  OCKSample
//
//  Created by Faye on 3/23/26.
//

import CareKitStore
import ResearchKit
import ResearchKitActiveTask

struct Surveys {

    // MARK: - Onboarding

    static let onboardingIdentifier = "onboarding"
    static let onboardingWelcomeIdentifier = "onboarding.welcome"
    static let onboardingOverviewIdentifier = "onboarding.overview"
    static let onboardingSignatureIdentifier = "onboarding.signature"
    static let onboardingRequestPermissionsIdentifier = "onboarding.permissions"
    static let onboardingCompletionIdentifier = "onboarding.completion"

    static func onboardingSurvey() -> ORKTask {
        let welcomeStep = ORKInstructionStep(identifier: onboardingWelcomeIdentifier)
        welcomeStep.title = "Welcome to BioMesh"
        welcomeStep.detailText = "This study explores how your daily caffeine intake " +
            "relates to anxiety, with sleep quality as a key mediator. " +
            "Tap Next to get started!"
        welcomeStep.image = UIImage(systemName: "hand.wave")
        welcomeStep.imageContentMode = .scaleAspectFit

        let completionStep = ORKCompletionStep(identifier: onboardingCompletionIdentifier)
        completionStep.title = "Enrollment Complete"
        completionStep.text = "You're all set! Your daily tasks are now ready."

        let orderedTask = ORKOrderedTask(
            identifier: onboardingIdentifier,
            steps: [welcomeStep, completionStep]
        )
        return orderedTask
    }

    // MARK: - Check-in Survey

    static let checkinIdentifier = "checkin"
    static let checkinAnxietyItemIdentifier = "checkin.anxiety"
    static let checkinSleepItemIdentifier = "checkin.sleep"
    static let checkinFormIdentifier = "checkin.form"

    static func checkInSurvey() -> ORKTask {
        let anxietyAnswer = ORKAnswerFormat.scale(
            withMaximumValue: 10,
            minimumValue: 1,
            defaultValue: 5,
            step: 1,
            vertical: false,
            maximumValueDescription: "Very anxious",
            minimumValueDescription: "Not anxious"
        )
        let anxietyItem = ORKFormItem(
            identifier: checkinAnxietyItemIdentifier,
            text: "How anxious do you feel today?",
            answerFormat: anxietyAnswer
        )
        anxietyItem.isOptional = false

        let sleepAnswer = ORKAnswerFormat.scale(
            withMaximumValue: 12,
            minimumValue: 0,
            defaultValue: 7,
            step: 1,
            vertical: false,
            maximumValueDescription: "12 hours",
            minimumValueDescription: "0 hours"
        )
        let sleepItem = ORKFormItem(
            identifier: checkinSleepItemIdentifier,
            text: "How many hours of sleep did you get last night?",
            answerFormat: sleepAnswer
        )
        sleepItem.isOptional = false

        let formStep = ORKFormStep(
            identifier: checkinFormIdentifier,
            title: "Daily Check-in",
            text: "Please answer the following questions."
        )
        formStep.formItems = [anxietyItem, sleepItem]
        formStep.isOptional = false

        let orderedTask = ORKOrderedTask(
            identifier: checkinIdentifier,
            steps: [formStep]
        )
        return orderedTask
    }

    static func extractAnswersFromCheckIn(
        _ result: ORKTaskResult
    ) -> [OCKOutcomeValue] {
        guard let formResult = result.stepResult(
            forStepIdentifier: checkinFormIdentifier
        )?.results else {
            assertionFailure("Failed to extract check-in answers")
            return []
        }

        var outcomeValues = [OCKOutcomeValue]()

        if let anxietyResult = formResult
            .first(where: { $0.identifier == checkinAnxietyItemIdentifier })
                as? ORKScaleQuestionResult,
           let anxietyAnswer = anxietyResult.scaleAnswer {
            var value = OCKOutcomeValue(Double(truncating: anxietyAnswer))
            value.kind = checkinAnxietyItemIdentifier
            outcomeValues.append(value)
        }

        if let sleepResult = formResult
            .first(where: { $0.identifier == checkinSleepItemIdentifier })
                as? ORKScaleQuestionResult,
           let sleepAnswer = sleepResult.scaleAnswer {
            var value = OCKOutcomeValue(Double(truncating: sleepAnswer))
            value.kind = checkinSleepItemIdentifier
            outcomeValues.append(value)
        }

        return outcomeValues
    }

    // MARK: - Range of Motion

    static let rangeOfMotionIdentifier = "rangeOfMotion"
    static let rangeOfMotionCompletionIdentifier = "rangeOfMotion.completion"

    static func rangeOfMotionCheck() -> ORKTask {
        let kneeTask = ORKOrderedTask.kneeRangeOfMotionTask(
            withIdentifier: rangeOfMotionIdentifier,
            limbOption: .left,
            intendedUseDescription: "Measure your left knee's range of motion.",
            options: [.excludeConclusion]
        )

        let completionStep = ORKCompletionStep(
            identifier: rangeOfMotionCompletionIdentifier
        )
        completionStep.title = "All Done!"
        completionStep.text = "Your range of motion has been recorded."

        var steps = kneeTask.steps
        steps.append(completionStep)

        let task = ORKOrderedTask(
            identifier: rangeOfMotionIdentifier,
            steps: steps
        )
        return task
    }

    static func extractRangeOfMotionOutcome(
        _ result: ORKTaskResult
    ) -> [OCKOutcomeValue] {
        let start = result.results?.compactMap { stepResult -> ORKRangeOfMotionResult? in
            guard let results = (stepResult as? ORKStepResult)?.results else {
                return nil
            }
            return results.compactMap { $0 as? ORKRangeOfMotionResult }.first
        }.first

        guard let romResult = start else {
            return []
        }

        var value = OCKOutcomeValue(romResult.range)
        value.kind = #keyPath(ORKRangeOfMotionResult.range)
        return [value]
    }
}
