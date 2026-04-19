//
//  SurveyViewSynchronizer.swift
//  OCKSample
//
//  Created by Faye on 3/31/26.
//

//
//  SurveyViewSynchronizer.swift
//  OCKSample
//

#if os(iOS)

import CareKit
import CareKitStore
import CareKitUI
import ResearchKit
import ResearchKitActiveTask
import UIKit
import os.log

final class SurveyViewSynchronizer: OCKSurveyTaskViewSynchronizer {

    override func updateView(
        _ view: OCKInstructionsTaskView,
        context: OCKSynchronizationContext<OCKTaskEvents>
    ) {
        super.updateView(view, context: context)

        guard let event = context.viewModel.first?.first,
              event.outcome != nil else {
            view.instructionsLabel.isHidden = true
            return
        }

        guard let task = event.task as? OCKTask else {
            view.instructionsLabel.isHidden = true
            return
        }

        switch task.uiKitSurvey {
        case .rangeOfMotion:
            let range = event.answer(kind: #keyPath(ORKRangeOfMotionResult.range))
            view.instructionsLabel.isHidden = false
            view.instructionsLabel.text = """
            Range of Motion: \(Int(range))°
            """

        case .tappingSpeed:
            let left = event.intAnswer(kind: "leftTapCount")
            let right = event.intAnswer(kind: "rightTapCount")
            let total = event.intAnswer(kind: "totalTapCount")

            view.instructionsLabel.isHidden = false
            view.instructionsLabel.text = """
            Left taps: \(left)
            Right taps: \(right)
            Total taps: \(total)
            """

        default:
            view.instructionsLabel.isHidden = true
        }
    }
}

#endif
