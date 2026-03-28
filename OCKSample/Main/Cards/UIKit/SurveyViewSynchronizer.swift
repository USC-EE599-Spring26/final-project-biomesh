//
//  SurveyViewSynchronizer.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(ResearchKit)

import CareKit
import CareKitStore
import CareKitUI
import ResearchKit
import UIKit
import os.log

@MainActor
final class SurveyViewSynchronizer: OCKSurveyTaskViewSynchronizer {

    override func updateView(
        _ view: OCKInstructionsTaskView,
        context: OCKSynchronizationContext<OCKTaskEvents>
    ) {
        super.updateView(view, context: context)

        guard let event = context.viewModel.first?.first,
              event.outcome != nil else {
            view.instructionsLabel.isHidden = true
            view.instructionsLabel.text = nil
            return
        }

        view.instructionsLabel.isHidden = false

        let sleep = event.answer(kind: Surveys.checkinSleepItemIdentifier)

        view.instructionsLabel.text = """
        Sleep: \(Int(sleep)) hours
        """
    }
}

#endif
