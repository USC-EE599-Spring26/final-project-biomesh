//
//  OCKTask+ResearchKitSwiftUI.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import Foundation

#if os(iOS)
extension OCKTask {
    var uiKitSurvey: Survey? {
        get {
            guard let surveyInfo = userInfo?[Constants.uiKitSurvey],
                  let surveyType = Survey(rawValue: surveyInfo) else {
                return nil
            }
            return surveyType
        }
        set {
            if userInfo == nil {
                userInfo = [:]
            }
            userInfo?[Constants.uiKitSurvey] = newValue?.rawValue
        }
    }
}
#endif
