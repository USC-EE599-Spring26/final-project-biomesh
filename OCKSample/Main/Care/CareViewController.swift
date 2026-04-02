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

import CareKit
import CareKitEssentials
import CareKitStore
import CareKitUI
import os.log
#if canImport(ResearchKit) && canImport(ResearchKitUI)
import ResearchKit
import ResearchKitUI
#endif
import ResearchKitSwiftUI
import SwiftUI
import UIKit

// swiftlint:disable type_body_length

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
            name: Notification.Name(
                rawValue: Constants.requestSync
            ),
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

    @objc private func updateSynchronizationProgress(
        _ notification: Notification
    ) {
        guard let receivedInfo = notification.userInfo as? [String: Any],
            let progress = receivedInfo[Constants.progressUpdate] as? Int else {
            return
        }

        switch progress {
        case 100:
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "\(progress)",
                style: .plain, target: self,
                action: #selector(self.synchronizeWithRemote)
            )
            self.navigationItem.rightBarButtonItem?.tintColor = self.view.tintColor

            // Give sometime for the user to see 100
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self else { return }
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: .refresh,
                    target: self,
                    action: #selector(self.synchronizeWithRemote)
                )
                self.navigationItem.rightBarButtonItem?.tintColor = self.navigationItem.leftBarButtonItem?.tintColor
            }
        default:
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "\(progress)",
                style: .plain, target: self,
                action: #selector(self.synchronizeWithRemote)
            )
            self.navigationItem.rightBarButtonItem?.tintColor = self.view.tintColor
        }
    }

    @objc private func synchronizeWithRemote() {
        guard !isSyncing else {
            return
        }
        isSyncing = true
        AppDelegateKey.defaultValue?.store.synchronize { error in
            let errorString = error?.localizedDescription ?? "Successful sync with remote!"
            Logger.feed.info("\(errorString)")
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if error != nil {
                    self.navigationItem.rightBarButtonItem?.tintColor = .red
                } else {
                    self.navigationItem.rightBarButtonItem?.tintColor = self.navigationItem.leftBarButtonItem?.tintColor
                }
                self.isSyncing = false
            }
        }
    }

    @objc private func reloadView(_ notification: Notification? = nil) {
        guard !isLoading else {
            return
        }
        self.reload()
    }

    /*
     This will be called each time the selected date changes.
     Use this as an opportunity to rebuild the content shown to the user.
     */
    override func dailyPageViewController(
        _ dailyPageViewController: OCKDailyPageViewController,
        prepare listViewController: OCKListViewController,
        for date: Date
    ) {
        self.isLoading = true

        Task {
            #if canImport(ResearchKit) && canImport(ResearchKitUI)
            guard await Utility.checkIfOnboardingIsComplete() else {

                let onboardSurvey = Onboard()
                var query = OCKEventQuery(for: Date())
                query.taskIDs = [Onboard.identifier()]
                let onboardCard = OCKSurveyTaskViewController(
                    eventQuery: query,
                    store: self.store,
                    survey: onboardSurvey.createSurvey(),
                    extractOutcome: { _ in
                        // Need to call reload sometime in the future
                        // since the OCKSurveyTaskViewControllerDelegate
                        // is broken.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.reload()
                        }
                        return [OCKOutcomeValue(Date())]
                    }
                )
                onboardCard.surveyDelegate = self

                listViewController.clear()
                listViewController.appendViewController(
                    onboardCard,
                    animated: false
                )
                self.isLoading = false
                return
            }

            // Always call this method to ensure dates for
            // queries are correct.
            let date = modifyDateIfNeeded(date)

            let isCurrentDay = isSameDay(as: date)

            // Only show the tip view on the current date
            if isCurrentDay {
                if Calendar.current.isDate(date, inSameDayAs: Date()) {
                    // Add a non-CareKit view into the list
                    let tipTitle = "Benefits of exercising"
                    let tipText = "Learn how activity can promote a healthy pregnancy."
                    let tipView = TipView()
                    tipView.headerView.titleLabel.text = tipTitle
                    tipView.headerView.detailLabel.text = tipText
                    tipView.imageView.image = UIImage(named: "exercise.jpg")
                    tipView.customStyle = CustomStylerKey.defaultValue
                    listViewController.appendView(tipView, animated: false)
                }
            }
            #endif

            await fetchAndDisplayTasks(on: listViewController, for: date)
        }
    }

    private func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(
            date,
            inSameDayAs: Date()
        )
    }

    private func modifyDateIfNeeded(_ date: Date) -> Date {
        guard date < .now else {
            return date
        }
        guard !isSameDay(as: date) else {
            return .now
        }
        return date.endOfDay
    }

    private func fetchAndDisplayTasks(
        on listViewController: OCKListViewController,
        for date: Date
    ) async {
        let tasks = await self.fetchTasks(on: date)
        appendTasks(tasks, to: listViewController, date: date)
    }

    private func fetchTasks(on date: Date) async -> [any OCKAnyTask] {
        var query = OCKTaskQuery(for: date)
        query.excludesTasksWithNoEvents = true
        do {
            let tasks = try await store.fetchAnyTasks(query: query)

            guard let tasksWithPriority = tasks as? [CareTask] else {
                Logger.feed.warning("Could not cast all tasks to \"CareTask\"")
                return tasks.filter { $0.id != Onboard.identifier() }
            }

            let orderedPriorityTasks = tasksWithPriority.sortedByPriority()

            let orderedTasks = orderedPriorityTasks.compactMap { orderedPriorityTask in
                tasks.first(where: { $0.id == orderedPriorityTask.id })
            }.filter { $0.id != Onboard.identifier() }

            return orderedTasks
        } catch {
            Logger.feed.error("Could not fetch tasks: \(error, privacy: .public)")
            return []
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func taskViewControllers(
        _ task: any OCKAnyTask,
        on date: Date
    ) -> [UIViewController]? {

        var query = OCKEventQuery(for: date)
        query.taskIDs = [task.id]

        if let standardTask = task as? OCKTask {

            switch standardTask.card {

            #if os(iOS)
            case .button:
                // This is a UIKit based card.
                let card = OCKButtonLogTaskViewController(
                    query: query,
                    store: self.store
                )

                return [card]

            case .checklist:
                // This is a UIKit based card.
                let card = OCKChecklistTaskViewController(
                    query: query,
                    store: self.store
                )

                return [card]
            #endif

            case .featured:
                // Can be implememented based off of midterm.
                return nil

            case .grid:
                // Can be implememented based off of midterm.
                return nil

            case .instruction:
                let card = EventQueryView<InstructionsTaskView>(
                    query: query
                )
                .padding(.vertical, swiftUIPadding)
                .formattedHostingController()

                return [card]

            case .link:
                // Can be implememented based off of midterm.
                return nil

            case .simple:

                let card = EventQueryView<SimpleTaskView>(
                    query: query
                )
                .padding(.vertical, swiftUIPadding)
                .formattedHostingController()

                return [card]

            case .survey:
                guard let card = researchSurveyViewController(
                    query: query,
                    task: standardTask
                ) else {
                    Logger.feed.warning(
                        "Unable to create research survey view controller"
                    )
                    return nil
                }

                return [card]

            #if canImport(ResearchKit) && canImport(ResearchKitUI)
            case .uiKitSurvey:
                guard let surveyTask = task as? OCKTask,
                      let survey = surveyTask.uiKitSurvey else {
                    Logger.feed.error("Can only use a survey for an \"OCKTask\", not \(task.id)")
                    return nil
                }

                let surveyCard = OCKSurveyTaskViewController(
                    eventQuery: query,
                    store: self.store,
                    survey: survey.type().createSurvey(),
                    viewSynchronizer: SurveyViewSynchronizer(),
                    extractOutcome: survey.type().extractAnswers
                )
                surveyCard.surveyDelegate = self
                return [surveyCard]
            #endif

            case .custom:
                let card = EventQueryView<MyCustomCardView>(
                    query: query
                )
                .padding(.vertical, swiftUIPadding)
                .formattedHostingController()

                return [card]

            default:
                return nil
            }

        } else if let healthTask = task as? OCKHealthKitTask {
            switch healthTask.card {

            case .labeledValue:
                // Can be implememented based off of midterm.
                return nil

            case .numericProgress:
                let card = EventQueryView<NumericProgressTaskView>(
                    query: query
                )
                .padding(.vertical, swiftUIPadding)
                .formattedHostingController()

                return [card]
            default:
                return nil
            }
        } else {
            return nil
        }

    }

    private func researchSurveyViewController(
        query: OCKEventQuery,
        task: OCKTask
    ) -> UIViewController? {

        guard let steps = task.surveySteps else {
            return nil
        }

        let surveyViewController = EventQueryContentView<ResearchSurveyView>(
            query: query
        ) {
            EventQueryContentView<ResearchCareForm>(
                query: query
            ) {
                ForEach(steps) { step in
                    ResearchFormStep(
                        title: task.title,
                        subtitle: task.instructions
                    ) {
                        ForEach(step.questions) { question in
                            question.view()
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
        tasks.compactMap {
            let cards = self.taskViewControllers(
                $0,
                on: date
            )
            cards?.forEach {
                if let carekitView = $0.view as? OCKView {
                    carekitView.customStyle = style
                }
                $0.view.isUserInteractionEnabled = isCurrentDay
                $0.view.alpha = !isCurrentDay ? 0.4 : 1.0
            }
            return cards
        }.forEach { (cards: [UIViewController]) in
            cards.forEach {
                let card = $0
                listViewController.appendViewController(card, animated: true)
            }
        }
        self.isLoading = false
    }
}

#if canImport(ResearchKit) && canImport(ResearchKitUI)
extension CareViewController: OCKSurveyTaskViewControllerDelegate {

    /*
    func surveyTask(
        viewController: OCKSurveyTaskViewController,
        for task: OCKAnyTask,
        didFinish result: Result<ORKTaskFinishReason, Error>
    ) {
        if case let .success(reason) = result, reason == .completed {
            reload()
        }
    } */
}
#endif

private extension View {
    /// Convert SwiftUI view to UIKit view.
    func formattedHostingController() -> UIHostingController<Self> {
        let viewController = UIHostingController(rootView: self)
        viewController.view.backgroundColor = .clear
        return viewController
    }
}
