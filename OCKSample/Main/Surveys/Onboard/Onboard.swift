//
//  Onboard.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore
import HealthKit
#if canImport(ResearchKit)
import ResearchKit
#endif

struct Onboard: Surveyable {
    static var surveyType: Survey {
        Survey.onboard
    }
}

#if canImport(ResearchKit)
extension Onboard {
    // swiftlint:disable:next function_body_length
    func createSurvey() -> ORKTask {

        // MARK: Welcome Step
        let welcomeInstructionStep = ORKInstructionStep(
            identifier: "\(identifier()).welcome"
        )
        welcomeInstructionStep.title = "Welcome to BioMesh"
        // swiftlint:disable:next line_length
        welcomeInstructionStep.detailText = "This study explores how caffeine intake affects anxiety and sleep. Tap Next to learn more before signing up."
        welcomeInstructionStep.image = UIImage(systemName: "cup.and.saucer.fill")
        welcomeInstructionStep.imageContentMode = .scaleAspectFit

        // MARK: Study Overview Step
        let studyOverviewInstructionStep = ORKInstructionStep(
            identifier: "\(identifier()).overview"
        )
        studyOverviewInstructionStep.title = "Before You Join"
        studyOverviewInstructionStep.iconImage = UIImage(systemName: "checkmark.seal.fill")

        let caffeineBodyItem = ORKBodyItem(
            text: "Log your daily caffeine and water intake to track consumption patterns.",
            detailText: nil,
            image: UIImage(systemName: "cup.and.saucer.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        let anxietyBodyItem = ORKBodyItem(
            text: "Record anxiety episodes so we can study the caffeine-anxiety relationship.",
            detailText: nil,
            image: UIImage(systemName: "brain.head.profile"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        let sleepBodyItem = ORKBodyItem(
            text: "Share your sleep and step data from HealthKit to measure recovery.",
            detailText: nil,
            image: UIImage(systemName: "moon.zzz.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        let secureDataBodyItem = ORKBodyItem(
            text: "Your data is encrypted, stored securely, and never shared without consent.",
            detailText: nil,
            image: UIImage(systemName: "lock.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        studyOverviewInstructionStep.bodyItems = [
            caffeineBodyItem,
            anxietyBodyItem,
            sleepBodyItem,
            secureDataBodyItem
        ]

        // MARK: Consent Signature Step
        let webViewStep = ORKWebViewStep(
            identifier: "\(identifier()).signatureCapture",
            html: informedConsentHTML
        )
        webViewStep.showSignatureAfterContent = true

        // MARK: Request Permissions Step
        // HealthKit types relevant to the caffeine-anxiety-sleep study
        let healthKitTypesToWrite: Set<HKSampleType> = [
            .categoryType(forIdentifier: .sleepAnalysis)!
        ]

        let healthKitTypesToRead: Set<HKObjectType> = [
            .quantityType(forIdentifier: .stepCount)!,
            .categoryType(forIdentifier: .sleepAnalysis)!,
            .quantityType(forIdentifier: .heartRate)!
        ]

        let healthKitPermissionType = ORKHealthKitPermissionType(
            sampleTypesToWrite: healthKitTypesToWrite,
            objectTypesToRead: healthKitTypesToRead
        )

        let notificationsPermissionType = ORKNotificationPermissionType(
            authorizationOptions: [.alert, .badge, .sound]
        )

        let motionPermissionType = ORKMotionActivityPermissionType()

        let requestPermissionsStep = ORKRequestPermissionsStep(
            identifier: "\(identifier()).requestPermissionsStep",
            permissionTypes: [
                healthKitPermissionType,
                notificationsPermissionType,
                motionPermissionType
            ]
        )
        requestPermissionsStep.title = "Health Data Request"
        // swiftlint:disable:next line_length
        requestPermissionsStep.text = "BioMesh uses your step count, sleep, and heart rate data to understand how caffeine affects your body. Please enable sharing below."

        // MARK: Completion Step
        let completionStep = ORKCompletionStep(
            identifier: "\(identifier()).completionStep"
        )
        completionStep.title = "You're All Set!"
        // swiftlint:disable:next line_length
        completionStep.text = "Welcome to BioMesh! Start by logging your first caffeinated drink. Your data will help us understand the caffeine-anxiety connection."

        let surveyTask = ORKOrderedTask(
            identifier: identifier(),
            steps: [
                welcomeInstructionStep,
                studyOverviewInstructionStep,
                webViewStep,
                requestPermissionsStep,
                completionStep
            ]
        )
        return surveyTask
    }

    func extractAnswers(_ result: ORKTaskResult) -> [CareKitStore.OCKOutcomeValue]? {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Utility.requestHealthKitPermissions()
        }
        return [OCKOutcomeValue(Date())]
    }
}
#endif
