//
//  TappingSpeed.swift
//  OCKSample
//
//  Created by Alarik Damrow on 4/19/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
#if canImport(ResearchKit) && canImport(ResearchKitActiveTask)
import ResearchKit
import ResearchKitActiveTask
#endif

struct TappingSpeed: Surveyable {
    static var surveyType: Survey {
        .tappingSpeed
    }
}

#if canImport(ResearchKit) && canImport(ResearchKitActiveTask)
extension TappingSpeed {

    private enum ResultKind {
        static let leftTapCount = "leftTapCount"
        static let rightTapCount = "rightTapCount"
        static let totalTapCount = "totalTapCount"
    }

    func createSurvey() -> ORKTask {
        let task = ORKOrderedTask.twoFingerTappingIntervalTask(
            withIdentifier: identifier(),
            intendedUseDescription: """
            This short tapping task helps estimate alertness and motor speed, which may change with caffeine timing
            and sleep quality.
            """,
            duration: 10,
            handOptions: [.left, .right],
            options: [.excludeConclusion]
        )

        let completionStep = ORKCompletionStep(identifier: "\(identifier()).completion")
        completionStep.title = "Nice work!"
        completionStep.detailText = "Your tapping results were recorded."

        task.addSteps(from: [completionStep])
        return task
    }

    func extractAnswers(_ result: ORKTaskResult) -> [OCKOutcomeValue]? {
        let tappingResults = flattenResults(result.results)
            .compactMap { $0 as? ORKTappingIntervalResult }

        guard !tappingResults.isEmpty else {
            assertionFailure("Failed to parse tapping interval result")
            return nil
        }

        let counts = tappingResults.map { $0.samples?.count ?? 0 }

        let leftCount = counts.first ?? 0
        let rightCount = counts.dropFirst().first ?? 0
        let totalCount = counts.reduce(0, +)

        var leftValue = OCKOutcomeValue(leftCount)
        leftValue.kind = ResultKind.leftTapCount

        var rightValue = OCKOutcomeValue(rightCount)
        rightValue.kind = ResultKind.rightTapCount

        var totalValue = OCKOutcomeValue(totalCount)
        totalValue.kind = ResultKind.totalTapCount

        return [leftValue, rightValue, totalValue]
    }

    private func flattenResults(_ results: [ORKResult]?) -> [ORKResult] {
        guard let results else { return [] }

        var flattened: [ORKResult] = []

        for result in results {
            flattened.append(result)

            if let stepResult = result as? ORKStepResult {
                flattened.append(contentsOf: flattenResults(stepResult.results))
            } else if let collectionResult = result as? ORKCollectionResult {
                flattened.append(contentsOf: flattenResults(collectionResult.results))
            }
        }

        return flattened
    }
}
#endif
