//
//  Surveys.swift
//  OCKSample
//
//  Created by Faye on 3/23/26.
//

import CareKitStore
import HealthKit
import ResearchKit
import ResearchKitActiveTask
import UIKit

struct Surveys {

    // MARK: - Onboarding

    static let onboardingIdentifier = "onboarding"
    static let onboardingWelcomeIdentifier = "onboarding.welcome"
    static let onboardingOverviewIdentifier = "onboarding.overview"
    static let onboardingSignatureIdentifier = "onboarding.signature"
    static let onboardingRequestPermissionsIdentifier = "onboarding.permissions"
    static let onboardingCompletionIdentifier = "onboarding.completion"

    static func onboardingSurvey() -> ORKTask {
        let welcomeStep = ORKInstructionStep(
            identifier: onboardingWelcomeIdentifier
        )
        welcomeStep.title = "Welcome!"
        welcomeStep.detailText = "Thank you for joining our study. Tap Next to learn more before signing up."
        welcomeStep.image = UIImage(systemName: "hand.wave.fill")
        welcomeStep.imageContentMode = .scaleAspectFit

        let overviewStep = ORKInstructionStep(
            identifier: onboardingOverviewIdentifier
        )
        overviewStep.title = "Before You Join"
        overviewStep.iconImage = UIImage(systemName: "checkmark.seal.fill")

        let heartBodyItem = ORKBodyItem(
            text: "The study will ask you to share some of your health data.",
            detailText: nil,
            image: UIImage(systemName: "heart.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        let completeTasksBodyItem = ORKBodyItem(
            text: "You will be asked to complete various tasks over the duration of the study.",
            detailText: nil,
            image: UIImage(systemName: "checkmark.circle.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        let signatureBodyItem = ORKBodyItem(
            text: "Before joining, we will ask you to sign an informed consent document.",
            detailText: nil,
            image: UIImage(systemName: "signature"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        let secureDataBodyItem = ORKBodyItem(
            text: "Your data is kept private and secure.",
            detailText: nil,
            image: UIImage(systemName: "lock.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        overviewStep.bodyItems = [
            heartBodyItem,
            completeTasksBodyItem,
            signatureBodyItem,
            secureDataBodyItem
        ]

        let consentStep = ORKWebViewStep(
            identifier: onboardingSignatureIdentifier,
            html: informedConsentHTML
        )
        consentStep.showSignatureAfterContent = true

        let healthKitTypesToWrite: Set<HKSampleType> = [
            .quantityType(forIdentifier: .bodyMassIndex)!,
            .quantityType(forIdentifier: .activeEnergyBurned)!,
            .workoutType()
        ]

        let healthKitTypesToRead: Set<HKObjectType> = [
            .characteristicType(forIdentifier: .dateOfBirth)!,
            .workoutType(),
            .quantityType(forIdentifier: .appleStandTime)!,
            .quantityType(forIdentifier: .appleExerciseTime)!
        ]

        let healthKitPermissionType = ORKHealthKitPermissionType(
            sampleTypesToWrite: healthKitTypesToWrite,
            objectTypesToRead: healthKitTypesToRead
        )

        let notificationsPermissionType = ORKNotificationPermissionType(
            authorizationOptions: [.alert, .badge, .sound]
        )

        let motionPermissionType = ORKMotionActivityPermissionType()

        let permissionsStep = ORKRequestPermissionsStep(
            identifier: onboardingRequestPermissionsIdentifier,
            permissionTypes: [
                healthKitPermissionType,
                notificationsPermissionType,
                motionPermissionType
            ]
        )
        permissionsStep.title = "Health Data Request"
        permissionsStep.text = "Please review the health data types below and enable sharing to contribute to the study."

        let completionStep = ORKCompletionStep(
            identifier: onboardingCompletionIdentifier
        )
        completionStep.title = "Enrollment Complete"
        completionStep.text = "Thank you for enrolling in this study. Your participation will contribute to meaningful research!"

        return ORKOrderedTask(
            identifier: onboardingIdentifier,
            steps: [
                welcomeStep,
                overviewStep,
                consentStep,
                permissionsStep,
                completionStep
            ]
        )
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

        return ORKOrderedTask(
            identifier: checkinIdentifier,
            steps: [formStep]
        )
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
            .first(where: { $0.identifier == checkinAnxietyItemIdentifier }) as? ORKScaleQuestionResult,
           let anxietyAnswer = anxietyResult.scaleAnswer {
            var value = OCKOutcomeValue(Double(truncating: anxietyAnswer))
            value.kind = checkinAnxietyItemIdentifier
            outcomeValues.append(value)
        }

        if let sleepResult = formResult
            .first(where: { $0.identifier == checkinSleepItemIdentifier }) as? ORKScaleQuestionResult,
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
            intendedUseDescription: nil,
            options: [.excludeConclusion]
        )

        let completionStep = ORKCompletionStep(
            identifier: rangeOfMotionCompletionIdentifier
        )
        completionStep.title = "All done!"
        completionStep.detailText = "We know the road to recovery can be tough. Keep up the good work!"

        var steps = kneeTask.steps
        steps.append(completionStep)

        return ORKOrderedTask(
            identifier: rangeOfMotionIdentifier,
            steps: steps
        )
    }

    static func extractRangeOfMotionOutcome(
        _ result: ORKTaskResult
    ) -> [OCKOutcomeValue] {
        let romResult = result.results?
            .compactMap { $0 as? ORKStepResult }
            .compactMap { $0.results }
            .flatMap { $0 }
            .compactMap { $0 as? ORKRangeOfMotionResult }
            .first

        guard let romResult else {
            assertionFailure("Failed to parse range of motion result")
            return []
        }

        var value = OCKOutcomeValue(romResult.range)
        value.kind = #keyPath(ORKRangeOfMotionResult.range)
        return [value]
    }
}
