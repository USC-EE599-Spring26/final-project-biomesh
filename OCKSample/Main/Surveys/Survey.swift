//
//  Survey.swift
//  OCKSample
//
//  Created by Alarik Damrow on 3/27/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if os(iOS)
import ResearchKit

enum Survey: String {
    case onboard
    case rangeOfMotion
    case checkIn

    func task() -> ORKTask {
        switch self {
        case .onboard:
            return Surveys.onboardingSurvey()
        case .rangeOfMotion:
            return Surveys.rangeOfMotionCheck()
        case .checkIn:
            return Surveys.checkInSurvey()
        }
    }
}
#endif
