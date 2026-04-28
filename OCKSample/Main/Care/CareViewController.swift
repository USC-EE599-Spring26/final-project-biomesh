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
// swiftlint:disable file_length
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

@MainActor
final class CareViewController: OCKDailyPageViewController, @unchecked Sendable {
	private var isSyncing = false
	private var isLoading = false
    private var didAutoPresentOnboarding = false
	private let swiftUIPadding: CGFloat = 15

    #if !os(watchOS) && canImport(ResearchKit) && canImport(ResearchKitUI)
    private var onboardingSurveyDelegate: OnboardingSurveyDelegate?
    #endif

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
                    // Re-run the daily page query so tasks/outcomes that were
                    // just pulled from parse (e.g. after re-login) appear in
                    // the Care tab without requiring the user to navigate away.
                    self.reloadView()
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
    override func dailyPageViewController(
        _ dailyPageViewController: OCKDailyPageViewController,
        prepare listViewController: OCKListViewController,
        for date: Date
    ) {
        self.isLoading = true

        Task {
            #if os(iOS)
            if await shouldShowOnboarding() {
                var query = OCKEventQuery(for: Date())
                query.taskIDs = [Onboard.identifier()]

                #if !os(watchOS) && canImport(ResearchKit) && canImport(ResearchKitUI)
                let onboardCard = EventQueryView<ActiveSurveyTaskCardView>(
                    query: query
                )
                .padding(.vertical, swiftUIPadding)
                .formattedHostingController()
                listViewController.clear()
                listViewController.appendViewController(onboardCard, animated: false)
                presentOnboardingSurveyIfNeeded()
                #endif

                self.isLoading = false
                return
            }
            #endif

            let date = modifyDateIfNeeded(date)

            #if os(iOS)
            let isCurrentDay = isSameDay(as: date)
            if isCurrentDay {
                if Calendar.current.isDate(date, inSameDayAs: Date()) {
                    let tipTitle = "Caffeine & Your Health"
                    let tipText = "High caffeine intake (>400 mg/day) is linked to increased anxiety"
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
                return tasks
            }
            let orderedPriorityTasks = tasksWithPriority.sortedByPriority()
            // Remove the onboarding task so it doesn't show after onboarding
            var filteredTasks = orderedPriorityTasks.compactMap { orderedPriorityTask in
                tasks.first(where: { $0.id == orderedPriorityTask.id })
            }
            #if os(iOS)
            filteredTasks = filteredTasks.filter { $0.id != Onboard.identifier() }
            #endif
            let orderedTasks = filteredTasks
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
            case .uiKitSurvey:
                guard standardTask.uiKitSurvey != nil else {
                    return nil
                }
                #if canImport(ResearchKit) && canImport(ResearchKitUI)
                let card = EventQueryView<ActiveSurveyTaskCardView>(
                    query: query
                )
                .padding(.vertical, swiftUIPadding)
                .formattedHostingController()
                return [card]
                #else
                return nil
                #endif

            case .button:
                let card = OCKButtonLogTaskViewController(
                    query: query,
                    store: self.store
                )
                return [card]

            case .checklist:
                let card = OCKChecklistTaskViewController(
                    query: query,
                    store: self.store
                )
                return [card]
            #endif

            case .featured:
                let card = EventQueryView<FeaturedTaskCardView>(
                    query: query
                )
                .padding(.vertical, swiftUIPadding)
                .formattedHostingController()
                return [card]

            case .grid:
                let card = EventQueryView<GridTaskCardView>(
                    query: query
                )
                .padding(.vertical, swiftUIPadding)
                .formattedHostingController()
                return [card]

            case .instruction:
                let card = EventQueryView<InstructionsTaskView>(
                    query: query
                )
                .padding(.vertical, swiftUIPadding)
                .formattedHostingController()
                return [card]

            case .link:
                let card = EventQueryView<LinkView>(
                    query: query
                )
                .padding(.vertical, swiftUIPadding)
                .formattedHostingController()
                return [card]

            case .labeledValue:
                let card = EventQueryView<StandardLabeledValueCardView>(
                    query: query
                )
                .padding(.vertical, swiftUIPadding)
                .formattedHostingController()
                return [card]

            case .numericProgress:
                let card = EventQueryView<StandardNumericProgressCardView>(
                    query: query
                )
                .padding(.vertical, swiftUIPadding)
                .formattedHostingController()
                return [card]

            case .simple:
                let card = EventQueryView<SimpleTaskView>(
                    query: query
                )
                .padding(.vertical, swiftUIPadding)
                .formattedHostingController()
                return [card]

            case .survey:
                let card = EventQueryView<AnswerSummarySurveyCardView>(
                    query: query
                )
                .padding(.vertical, swiftUIPadding)
                .formattedHostingController()
                return [card]

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
                let card = EventQueryView<LabeledValueTaskView>(
                    query: query
                )
                .padding(.vertical, swiftUIPadding)
                .formattedHostingController()
                return [card]

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

    #if !os(watchOS) && canImport(ResearchKit) && canImport(ResearchKitUI)
    private func shouldShowOnboarding() async -> Bool {
        guard let user = try? await User.current(),
              user.needsOnboarding == true else {
            return false
        }

        return await !Utility.checkIfOnboardingIsComplete()
    }

    private func presentOnboardingSurveyIfNeeded() {
        guard !didAutoPresentOnboarding,
              presentedViewController == nil else {
            return
        }

        didAutoPresentOnboarding = true
        let onboarding = Onboard()
        let surveyController = ORKTaskViewController(
            task: onboarding.createSurvey(),
            taskRun: nil
        )
        let delegate = OnboardingSurveyDelegate { [weak self] result in
            guard let self else { return }
            let values = onboarding.extractAnswers(result) ?? [OCKOutcomeValue(Date())]
            Task {
                await self.saveOnboardingOutcome(values)
            }
        }

        onboardingSurveyDelegate = delegate
        surveyController.delegate = delegate

        DispatchQueue.main.async { [weak self] in
            guard let self,
                  self.presentedViewController == nil else {
                return
            }
            self.present(surveyController, animated: true)
        }
    }

    private func saveOnboardingOutcome(_ values: [OCKOutcomeValue]) async {
        guard !values.isEmpty else { return }

        do {
            var query = OCKEventQuery(for: Date())
            query.taskIDs = [Onboard.identifier()]

            guard let event = try await store.fetchAnyEvents(query: query).first else {
                Logger.feed.error("Could not fetch onboarding event to save outcome")
                return
            }

            if var outcome = event.outcome {
                outcome.values = values
                _ = try await store.updateAnyOutcome(outcome)
            } else {
                let outcome = OCKOutcome(
                    taskUUID: event.task.uuid,
                    taskOccurrenceIndex: event.scheduleEvent.occurrence,
                    values: values
                )
                _ = try await store.addAnyOutcome(outcome)
            }

            reloadView()
            await markOnboardingComplete()
        } catch {
            Logger.feed.error("Could not save onboarding outcome: \(error, privacy: .public)")
        }
    }

    private func markOnboardingComplete() async {
        do {
            var user = try await User.current()
            user.needsOnboarding = false
            _ = try await user.save()
        } catch {
            Logger.feed.error("Could not update onboarding flag: \(error, privacy: .public)")
        }
    }
    #endif

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

#if !os(watchOS) && canImport(ResearchKit) && canImport(ResearchKitUI)
private final class OnboardingSurveyDelegate: NSObject, @MainActor ORKTaskViewControllerDelegate {
    let onComplete: (ORKTaskResult) -> Void

    init(onComplete: @escaping (ORKTaskResult) -> Void) {
        self.onComplete = onComplete
    }

    func taskViewController(
        _ taskViewController: ORKTaskViewController,
        didFinishWith reason: ORKTaskFinishReason,
        error: (any Error)?
    ) {
        if reason == .completed {
            onComplete(taskViewController.result)
        }
        taskViewController.dismiss(animated: true)
    }
}
#endif

private extension View {
    func formattedHostingController() -> UIHostingController<Self> {
        let viewController = UIHostingController(rootView: self)
        viewController.view.backgroundColor = .clear
        viewController.sizingOptions = .intrinsicContentSize
        return viewController
    }
}
