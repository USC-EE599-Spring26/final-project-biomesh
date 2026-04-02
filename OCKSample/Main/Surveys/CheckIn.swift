//
//  CheckIn.swift
//  OCKSample
//
//  Created by Ray on 02/04/2026.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
#if canImport(ResearchKit)
import ResearchKit
#endif

struct CheckIn: Surveyable {
    static var surveyType: Survey {
        .checkIn
    }
}

#if canImport(ResearchKit)
extension CheckIn {
    static let stressItemIdentifier = "checkin.stress"
    static let sleepItemIdentifier = "checkin.sleep"

    func createSurvey() -> ORKTask {
        let stressQuestion = ORKQuestionStep(
            identifier: Self.stressItemIdentifier,
            title: "How stressed do you feel today?",
            answer: ORKAnswerFormat.scale(
                withMaximumValue: 10,
                minimumValue: 0,
                defaultValue: 5,
                step: 1,
                vertical: false,
                maximumValueDescription: "Very high",
                minimumValueDescription: "None"
            )
        )

        let sleepQuestion = ORKQuestionStep(
            identifier: Self.sleepItemIdentifier,
            title: "How many hours did you sleep last night?",
            answer: ORKAnswerFormat.decimalAnswerFormat(withUnit: "hours")
        )

        let completionStep = ORKCompletionStep(identifier: "\(identifier()).completion")
        completionStep.title = "Check-in Complete"

        return ORKOrderedTask(
            identifier: identifier(),
            steps: [stressQuestion, sleepQuestion, completionStep]
        )
    }

    func extractAnswers(_ result: ORKTaskResult) -> [OCKOutcomeValue]? {
        let stepResults = result.results?.compactMap { $0 as? ORKStepResult } ?? []
        var values = [OCKOutcomeValue]()

        if let stressResult = stepResults
            .first(where: { $0.identifier == Self.stressItemIdentifier })?
            .firstResult as? ORKScaleQuestionResult,
           let stress = stressResult.scaleAnswer?.doubleValue {
            var value = OCKOutcomeValue(stress)
            value.kind = Self.stressItemIdentifier
            values.append(value)
        }

        if let sleepResult = stepResults
            .first(where: { $0.identifier == Self.sleepItemIdentifier })?
            .firstResult as? ORKNumericQuestionResult,
           let sleep = sleepResult.numericAnswer?.doubleValue {
            var value = OCKOutcomeValue(sleep)
            value.kind = Self.sleepItemIdentifier
            values.append(value)
        }

        return values.isEmpty ? nil : values
    }
}
#endif
