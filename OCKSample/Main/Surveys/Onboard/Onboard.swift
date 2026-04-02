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
    /*
     Updated for the BioMesh onboarding experience.
     The onboarding now explains the app's purpose:
     tracking caffeine intake, sleep, movement, and anxiety.
     */
    func createSurvey() -> ORKTask {
        // Welcome step
        let welcomeInstructionStep = ORKInstructionStep(
            identifier: "\(identifier()).welcome"
        )

        welcomeInstructionStep.title = "Welcome to BioMesh"
        welcomeInstructionStep.detailText = """
        BioMesh helps you understand how your daily habits—especially caffeine intake, sleep, activity, and anxiety—connect over time. Tap Next to learn more before getting started.
        """
        welcomeInstructionStep.image = UIImage(systemName: "waveform.path.ecg")
        welcomeInstructionStep.imageContentMode = .scaleAspectFit

        // Study / app overview step
        let studyOverviewInstructionStep = ORKInstructionStep(
            identifier: "\(identifier()).overview"
        )

        studyOverviewInstructionStep.title = "How BioMesh Works"
        studyOverviewInstructionStep.iconImage = UIImage(systemName: "bed.double.fill")

        let caffeineBodyItem = ORKBodyItem(
            text: "Log your caffeine intake so you can observe how it may affect your sleep and anxiety.",
            detailText: nil,
            image: UIImage(systemName: "cup.and.saucer.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        let sleepBodyItem = ORKBodyItem(
            text: "BioMesh can read sleep-related data and daily activity data from HealthKit, such as sleep duration and steps.",
            detailText: nil,
            image: UIImage(systemName: "moon.zzz.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        let checkInBodyItem = ORKBodyItem(
            text: "Complete short check-ins about anxiety, hydration, and daily routines to build a clearer picture of your well-being.",
            detailText: nil,
            image: UIImage(systemName: "checkmark.circle.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        let privacyBodyItem = ORKBodyItem(
            text: "Your information is stored securely and used only to support your care experience and app-based tracking.",
            detailText: nil,
            image: UIImage(systemName: "lock.shield.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        studyOverviewInstructionStep.bodyItems = [
            caffeineBodyItem,
            sleepBodyItem,
            checkInBodyItem,
            privacyBodyItem
        ]

        // Consent / signature step
        let webViewStep = ORKWebViewStep(
            identifier: "\(identifier()).signatureCapture",
            html: informedConsentHTML
        )

        webViewStep.showSignatureAfterContent = true

        // HealthKit permissions step
        let healthKitTypesToWrite: Set<HKSampleType> = [
            .workoutType()
        ]

        let healthKitTypesToRead: Set<HKObjectType> = [
            .quantityType(forIdentifier: .stepCount)!,
            .categoryType(forIdentifier: .sleepAnalysis)!,
            .workoutType()
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

        requestPermissionsStep.title = "Allow BioMesh Permissions"
        requestPermissionsStep.text = """
        BioMesh requests access to selected HealthKit, motion, and notification data so it can track sleep, activity, and reminders more accurately.
        """

        // Completion step
        let completionStep = ORKCompletionStep(
            identifier: "\(identifier()).completionStep"
        )

        completionStep.title = "You're All Set"
        completionStep.text = """
        Welcome to BioMesh. Your onboarding is complete, and you can now begin tracking caffeine, sleep, activity, and anxiety patterns.
        """

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
