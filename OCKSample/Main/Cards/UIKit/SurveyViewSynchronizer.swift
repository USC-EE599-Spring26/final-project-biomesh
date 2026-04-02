//
//  SurveyViewSynchronizer.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(ResearchKit) && canImport(ResearchKitActiveTask)

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

        let event = context.viewModel.first?.first
        let hasOutcome = event?.outcome != nil
        let taskID = event?.task.id

        var labelText: String?
        var shouldHide = true

        if hasOutcome, let event {
            shouldHide = false

            switch taskID {
            case RangeOfMotion.identifier():
                let range = event.answer(kind: "range")
                labelText = "Range of motion: \(Int(range))°"

            case Onboard.identifier():
                labelText = "Enrollment completed."

            case CheckIn.identifier():
                let stress = event.answer(kind: CheckIn.stressItemIdentifier)
                let sleep = event.answer(kind: CheckIn.sleepItemIdentifier)
                labelText = "Stress: \(Int(stress))/10, Sleep: \(Int(sleep)) hrs"

            default:
                labelText = "Survey completed."
            }
        }

        DispatchQueue.main.async {
            view.instructionsLabel.isHidden = shouldHide
            view.instructionsLabel.text = labelText
        }
    }
}

#endif
