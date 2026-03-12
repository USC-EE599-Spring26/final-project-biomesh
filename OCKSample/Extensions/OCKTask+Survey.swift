//
//  OCKTask+Survey.swift
//  OCKSample
//
//  Created by Alarik Damrow on 3/11/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore
import ResearchKitSwiftUI

extension OCKTask {
    var surveySteps: [SurveyStep]? {
        get {
            guard let raw = userInfo?["surveySteps"],
                  let data = raw.data(using: .utf8) else {
                return nil
            }

            return try? JSONDecoder().decode([SurveyStep].self, from: data)
        }
        set {
            if userInfo == nil {
                userInfo = [:]
            }

            guard let newValue else {
                userInfo?["surveySteps"] = nil
                return
            }

            guard let data = try? JSONEncoder().encode(newValue),
                  let raw = String(data: data, encoding: .utf8) else {
                return
            }

            userInfo?["surveySteps"] = raw
        }
    }
}
