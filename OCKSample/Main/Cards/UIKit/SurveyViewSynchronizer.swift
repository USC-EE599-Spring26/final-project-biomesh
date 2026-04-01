#if canImport(ResearchKit)

import CareKit
import CareKitStore
import CareKitUI
import ResearchKit
import ResearchKitActiveTask
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

        let taskID = event.task.id
        view.instructionsLabel.isHidden = false

        switch taskID {


        case TaskID.rangeOfMotion:
            let range = event.answer(kind: #keyPath(ORKRangeOfMotionResult.range))

            view.instructionsLabel.text = """
            Task ID: \(taskID)

            Range of Motion: \(Int(range))°
            """


        case "\(TaskID.qualityOfLife)-stress":
            let stress = event.answer(kind: TaskID.qualityOfLife)

            view.instructionsLabel.text = """
            Task ID: \(taskID)

            Stress Level: \(Int(stress))/10
            """


        default:
            view.instructionsLabel.text = """
            Task ID: \(taskID)

            Completed
            """
        }
    }
}

#endif
