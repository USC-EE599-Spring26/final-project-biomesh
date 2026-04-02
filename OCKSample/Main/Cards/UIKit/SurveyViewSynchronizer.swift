//
//  SurveyViewSynchronizer.swift
//  OCKSample
//
//  Created by Faye on 3/31/26.
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

        if let event = context.viewModel.first?.first, event.outcome != nil {
            view.instructionsLabel.isHidden = false

            // TODO: Modify this so the instruction label shows correctly
            // for each Task/Card. Hint - Each event has a task. How can you
            // use this task to determine what instruction answers should show?
            // Look at how CareViewController differentiates between surveys.

            guard let task = event.task as? OCKTask else {
                return
            }

            switch task.uiKitSurvey {
            case .rangeOfMotion:
                let range = event.answer(kind: #keyPath(ORKRangeOfMotionResult.range))
                view.instructionsLabel.text = """
                Range of Motion: \(Int(range))°
                """

            default:
                view.instructionsLabel.isHidden = true
            }
        } else {
            view.instructionsLabel.isHidden = true
        }
    }
}

#endif
