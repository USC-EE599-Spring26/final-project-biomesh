//
//  Surveyable.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore
#if canImport(ResearchKit)
import ResearchKit
#endif

/**
 Correlates a CareKit task with a ResearchKit task.
 */
protocol Surveyable {
    /// The type of survey.
    static var surveyType: Survey { get }
    /// The unique identifier of the survey.
    static func identifier() -> String
    #if canImport(ResearchKit)
    /// Creates the survey.
    func createSurvey() -> ORKTask
    /// Extracts the answers from the survey.
    func extractAnswers(_ result: ORKTaskResult) -> [OCKOutcomeValue]?
    #endif
}

extension Surveyable {
    static func identifier() -> String {
        surveyType.rawValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The unique identifier of the survey.
    func identifier() -> String {
        Self.identifier()
    }
}
