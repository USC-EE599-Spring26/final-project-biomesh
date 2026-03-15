/*
 Copyright (c) 2019, Apple Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.

 3. Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
// swiftlint:disable type_body_length
// swiftlint:disable cyclomatic_complexity

import CareKit
import CareKitEssentials
import CareKitStore
import CareKitUI
import os.log
import ResearchKitSwiftUI
import SwiftUI
import UIKit

@MainActor
final class CareViewController: OCKDailyPageViewController, @unchecked Sendable {

    private var isSyncing = false
    private var isLoading = false

    private let swiftUIPadding: CGFloat = 15

    private var style: Styler {
        CustomStylerKey.defaultValue
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(synchronizeWithRemote)
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(synchronizeWithRemote),
            name: Notification.Name(rawValue: Constants.requestSync),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateSynchronizationProgress(_:)),
            name: Notification.Name(rawValue: Constants.progressUpdate),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadView(_:)),
            name: Notification.Name(rawValue: Constants.finishedAskingForPermission),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadView(_:)),
            name: Notification.Name(rawValue: Constants.shouldRefreshView),
            object: nil
        )
    }
    @objc
    private func updateSynchronizationProgress(_ notification: Notification) {
        guard
            let receivedInfo = notification.userInfo as? [String: Any],
            let progress = receivedInfo[Constants.progressUpdate] as? Int
        else {
            return
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "\(progress)",
            style: .plain,
            target: self,
            action: #selector(self.synchronizeWithRemote)
        )
        navigationItem.rightBarButtonItem?.tintColor = view.tintColor

        guard progress == 100 else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }

            self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .refresh,
                target: self,
                action: #selector(self.synchronizeWithRemote)
            )
            self.navigationItem.rightBarButtonItem?.tintColor = self.view.tintColor
        }
    }

    @objc
    private func synchronizeWithRemote() {
        guard !isSyncing else { return }

        isSyncing = true

        AppDelegateKey.defaultValue?.store.synchronize { error in
            let message = error?.localizedDescription ?? "Successful sync with remote!"
            Logger.feed.info("\(message)")

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                self.navigationItem.rightBarButtonItem?.tintColor =
                    error != nil ? .red : self.view.tintColor
                self.isSyncing = false
            }
        }
    }
    @objc
    private func reloadView(_ notification: Notification? = nil) {
        guard !isLoading else { return }
        reload()
    }
    override func dailyPageViewController(
        _ dailyPageViewController: OCKDailyPageViewController,
        prepare listViewController: OCKListViewController,
        for date: Date
    ) {
        isLoading = true

        let displayDate = modifyDateIfNeeded(date)
        let isCurrentDay = isSameDay(as: displayDate)

        #if os(iOS)
        if isCurrentDay && Calendar.current.isDate(displayDate, inSameDayAs: Date()) {
            let tipView = TipView()
            tipView.headerView.titleLabel.text = "Caffeine & Your Health"
            tipView.headerView.detailLabel.text =
                "High caffeine intake (>400 mg/day) is linked to increased anxiety"
            tipView.imageView.image = UIImage(named: "exercise.jpg")
            tipView.customStyle = CustomStylerKey.defaultValue
            listViewController.appendView(tipView, animated: false)
        }
        #endif

        fetchAndDisplayTasks(on: listViewController, for: displayDate)
    }
    private func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }

    private func modifyDateIfNeeded(_ date: Date) -> Date {
        guard date < .now else { return date }
        guard !isSameDay(as: date) else { return .now }
        return date.endOfDay
    }
    private func fetchAndDisplayTasks(
        on listViewController: OCKListViewController,
        for date: Date
    ) {
        Task {
            let tasks = await fetchTasks(on: date)
            appendTasks(tasks, to: listViewController, date: date)
        }
    }

    private func fetchTasks(on date: Date) async -> [any OCKAnyTask] {
        var query = OCKTaskQuery(for: date)
        query.excludesTasksWithNoEvents = true

        do {
            let tasks = try await store.fetchAnyTasks(query: query)

            return tasks.sorted { lhs, rhs in
                let lhsPriority = (lhs as? CareTask)?.priority ?? 100
                let rhsPriority = (rhs as? CareTask)?.priority ?? 100

                if lhsPriority != rhsPriority {
                    return lhsPriority < rhsPriority
                }

                let lhsTitle = title(for: lhs)
                let rhsTitle = title(for: rhs)

                return lhsTitle.localizedCaseInsensitiveCompare(rhsTitle) == .orderedAscending
            }
        } catch {
            Logger.feed.error("Could not fetch tasks: \(error, privacy: .public)")
            return []
        }
    }

    private func title(for task: any OCKAnyTask) -> String {
        if let task = task as? OCKTask {
            return task.title ?? task.id
        }
        if let task = task as? OCKHealthKitTask {
            return task.title ?? task.id
        }
        return task.id
    }
    private func taskViewControllers(
        _ task: any OCKAnyTask,
        on date: Date
    ) -> [UIViewController]? {
        var query = OCKEventQuery(for: date)
        query.taskIDs = [task.id]

        if let standardTask = task as? OCKTask {
            return standardTaskViewControllers(for: standardTask, query: query)
        }

        if let healthTask = task as? OCKHealthKitTask {
            return healthTaskViewControllers(for: healthTask, query: query)
        }

        return nil
    }

    private func standardTaskViewControllers(
        for task: OCKTask,
        query: OCKEventQuery
    ) -> [UIViewController]? {
        switch task.card {
        case .button:
            #if os(iOS)
            return [OCKButtonLogTaskViewController(query: query, store: store)]
            #else
            return []
            #endif

        case .checklist:
            #if os(iOS)
            return [OCKChecklistTaskViewController(query: query, store: store)]
            #else
            return []
            #endif

        case .simple:
            return [
                EventQueryView<SimpleTaskView>(query: query)
                    .formattedHostingController()
            ]

        case .instruction:
            #if os(iOS)
            return [OCKInstructionsTaskViewController(query: query, store: store)]
            #else
            return [
                EventQueryView<InstructionsTaskView>(query: query)
                    .formattedHostingController()
            ]
            #endif

        case .labeledValue:
            return [
                EventQueryView<LabeledValueTaskView>(query: query)
                    .formattedHostingController()
            ]

        case .numericProgress:
            return [
                EventQueryView<NumericProgressTaskView>(query: query)
                    .formattedHostingController()
            ]

        case .grid:
            #if os(iOS)
            return [OCKGridTaskViewController(query: query, store: store)]
            #else
            return []
            #endif

        case .survey:
            guard let card = researchSurveyViewController(query: query, task: task) else {
                Logger.feed.warning("Unable to create research survey view controller")
                return nil
            }
            return [card]

        case .custom:
            return [
                EventQueryView<MyCustomCardView>(query: query)
                    .padding(.vertical, swiftUIPadding)
                    .formattedHostingController()
            ]

        case .featured, .link:
            return nil
        }
    }

    private func healthTaskViewControllers(
        for task: OCKHealthKitTask,
        query: OCKEventQuery
    ) -> [UIViewController]? {
        switch task.card {
        case .numericProgress:
            return [
                EventQueryView<NumericProgressTaskView>(query: query)
                    .formattedHostingController()
            ]

        case .labeledValue:
            return [
                EventQueryView<LabeledValueTaskView>(query: query)
                    .formattedHostingController()
            ]

        case .simple:
            return [
                EventQueryView<SimpleTaskView>(query: query)
                    .formattedHostingController()
            ]

        case .instruction:
            return [
                EventQueryView<InstructionsTaskView>(query: query)
                    .formattedHostingController()
            ]

        case .custom:
            return [
                EventQueryView<MyCustomCardView>(query: query)
                    .padding(.vertical, swiftUIPadding)
                    .formattedHostingController()
            ]

        case .survey, .button, .checklist, .grid, .featured, .link:
            return nil
        }
    }
    private func researchSurveyViewController(
        query: OCKEventQuery,
        task: OCKTask
    ) -> UIViewController? {
        guard let steps = task.surveySteps else { return nil }

        let surveyViewController = EventQueryContentView<ResearchSurveyView>(
            query: query
        ) {
            EventQueryContentView<ResearchCareForm>(query: query) {
                ForEach(steps.indices, id: \.self) { stepIndex in
                    ResearchFormStep(
                        title: task.title ?? task.id,
                        subtitle: task.instructions
                    ) {
                        ForEach(steps[stepIndex].questions.indices, id: \.self) { questionIndex in
                            SurveyQuestionView(
                                question: steps[stepIndex].questions[questionIndex]
                            )
                        }
                    }
                }
            }
        }
        .padding(.vertical, swiftUIPadding)
        .formattedHostingController()

        return surveyViewController
    }
    private func appendTasks(
        _ tasks: [any OCKAnyTask],
        to listViewController: OCKListViewController,
        date: Date
    ) {
        let isCurrentDay = isSameDay(as: date)

        tasks.compactMap { taskViewControllers($0, on: date) }
            .forEach { cards in
                cards.forEach { card in
                    if let careKitView = card.view as? OCKView {
                        careKitView.customStyle = style
                    }

                    card.view.isUserInteractionEnabled = isCurrentDay
                    card.view.alpha = isCurrentDay ? 1.0 : 0.4
                    listViewController.appendViewController(card, animated: true)
                }
            }

        isLoading = false
    }
}

private extension View {
    func formattedHostingController() -> UIHostingController<Self> {
        let controller = UIHostingController(rootView: self)
        controller.view.backgroundColor = .clear
        return controller
    }
}
