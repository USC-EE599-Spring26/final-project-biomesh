//
//  OCKTask+Card.swift
//  OCKSample
//
//  Created by Corey Baker on 2/26/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore

extension OCKTask: CareTask {}

extension OCKTask {
    #if os(iOS)
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
                userInfo = .init()
            }
            userInfo?[Constants.uiKitSurvey] = newValue?.rawValue
        }
    }
    #endif
}

