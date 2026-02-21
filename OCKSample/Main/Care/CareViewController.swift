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
import SwiftUI
import UIKit
@MainActor
final class CareViewController: OCKDailyPageViewController, @unchecked Sendable {
    private var isSyncing = false
    private var isLoading = false
    private var style: Styler { CustomStylerKey.defaultValue }
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
    @objc private func updateSynchronizationProgress(_ notification: Notification) {
        guard
            let receivedInfo = notification.userInfo as? [String: Any],
            let progress = receivedInfo[Constants.progressUpdate] as? Int
        else { return }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "\(progress)",
            style: .plain,
            target: self,
            action: #selector(synchronizeWithRemote)
        )
        navigationItem.rightBarButtonItem?.tintColor = view.tintColor
        if progress == 100 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self else { return }
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: .refresh,
                    target: self,
                    action: #selector(self.synchronizeWithRemote)
                )
                self.navigationItem.rightBarButtonItem?.tintColor = self.navigationItem.leftBarButtonItem?.tintColor
            }
        }
    }
    
    @objc private func synchronizeWithRemote() {
        guard !isSyncing else { return }
        isSyncing = true
        AppDelegateKey.defaultValue?.store.synchronize { error in
            let message = error?.localizedDescription ?? "Successful sync with remote!"
            Logger.feed.info("\(message)")
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.navigationItem.rightBarButtonItem?.tintColor = (error == nil)
                ? self.navigationItem.leftBarButtonItem?.tintColor
                : .red
                self.isSyncing = false
            }
        }
    }
    
    @objc private func reloadView(_ notification: Notification? = nil) {
        guard !isLoading else { return }
        reload()
    }
    override func dailyPageViewController(
        _ dailyPageViewController: OCKDailyPageViewController,
        prepare listViewController: OCKListViewController,
        for date: Date
    ) {
        isLoading = true
        
        let resolvedDate = modifyDateIfNeeded(date)
        let isCurrentDay = isSameDay(as: resolvedDate)
        
#if os(iOS)
        if isCurrentDay, Calendar.current.isDate(resolvedDate, inSameDayAs: Date()) {
            let tipView = TipView()
            tipView.headerView.titleLabel.text = "Benefits of exercising"
            tipView.headerView.detailLabel.text = "Learn how activity can promote a healthy pregnancy."
            tipView.imageView.image = UIImage(named: "exercise.jpg")
            tipView.customStyle = style
            listViewController.appendView(tipView, animated: false)
        }
#endif
        
        fetchAndDisplayTasks(on: listViewController, for: resolvedDate)
    }
    
    private func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    private func modifyDateIfNeeded(_ date: Date) -> Date {
        // Keep "future" dates unchanged
        guard date < .now else { return date }
        // If it's today, align to now
        guard !isSameDay(as: date) else { return .now }
        // Otherwise show end-of-day for past dates
        return date.endOfDay
    }
    
    private func fetchAndDisplayTasks(on listViewController: OCKListViewController, for date: Date) {
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
            let orderedTasks = TaskID.ordered.compactMap { orderedTaskID in
                tasks.first(where: { $0.id == orderedTaskID })
            }
            let orderedIDs = Set(TaskID.ordered)
            let userTasks = tasks
                .filter { !orderedIDs.contains($0.id) }
                .sorted {
                    let t0 = ($0 as? OCKTask)?.title ?? $0.id
                    let t1 = ($1 as? OCKTask)?.title ?? $1.id
                    return t0.localizedCaseInsensitiveCompare(t1) == .orderedAscending
                }
            
            return orderedTasks + userTasks
        } catch {
            Logger.feed.error("Could not fetch tasks: \(error, privacy: .public)")
            return []
        }
    }
    private func taskViewControllers(_ task: any OCKAnyTask, on date: Date) -> [UIViewController]? {
        var query = OCKEventQuery(for: date)
        query.taskIDs = [task.id]
        switch task.id {
        case TaskID.steps:
            return [EventQueryView<NumericProgressTaskView>(query: query).formattedHostingController()]
        case TaskID.ovulationTestResult:
            return [EventQueryView<LabeledValueTaskView>(query: query).formattedHostingController()]
        case TaskID.stretch:
            return [EventQueryView<InstructionsTaskView>(query: query).formattedHostingController()]
            
        case TaskID.kegels:
            return [EventQueryView<SimpleTaskView>(query: query).formattedHostingController()]
            
#if os(iOS)
        case TaskID.doxylamine:
            return [OCKChecklistTaskViewController(query: query, store: store)]
#endif
            
        case TaskID.nausea:
#if os(iOS)
            return [OCKButtonLogTaskViewController(query: query, store: store)]
#else
            return []
#endif
            
        default:
            break
        }
        guard let selected = userSelectedCardType(for: task) else { return nil }
        
        switch selected {
        case "simple":
            return [EventQueryView<SimpleTaskView>(query: query).formattedHostingController()]
            
        case "instructions":
            return [EventQueryView<InstructionsTaskView>(query: query).formattedHostingController()]
            
        case "numericProgress":
            return [EventQueryView<NumericProgressTaskView>(query: query).formattedHostingController()]
            
        case "grid":
            return [OCKGridTaskViewController(query: query, store: store)]
            
        case "labeledValue":
            return [EventQueryView<LabeledValueTaskView>(query: query).formattedHostingController()]
        case "linkView":
            guard let t = task as? OCKTask else {
                return [OCKInstructionsTaskViewController(query: query, store: store)]
            }
            return [LinkTaskViewController(task: t, query: query, store: store)]
            
#if os(iOS)
        case "checklist":
            return [OCKChecklistTaskViewController(query: query, store: store)]
            
        case "buttonLog":
            return [OCKButtonLogTaskViewController(query: query, store: store)]
#else
        case "checklist", "buttonLog":
            return []
#endif
        case "featuredContent":
            return nil
            
        default:
            return nil
        }
    }
    
    private func userSelectedCardType(for task: any OCKAnyTask) -> String? {
        guard let task = task as? OCKTask else { return nil }
        guard let tags = task.tags else { return nil }
        guard let match = tags.first(where: { $0.hasPrefix("cardType:") }) else { return nil }
        return String(match.dropFirst("cardType:".count))
    }
    private func appendTasks(
        _ tasks: [any OCKAnyTask],
        to listViewController: OCKListViewController,
        date: Date
    ) {
        let isCurrentDay = isSameDay(as: date)

        // Toggle this on/off as needed
        let debug = true

        for task in tasks {
            if debug, let t = task as? OCKTask {
                print("APPEND TASK:", (t.title ?? "(nil title)"), "id:", t.id, "tags:", t.tags ?? [])
            } else if debug {
                print("APPEND TASK:", task.id)
            }
            if userSelectedCardType(for: task) == "featuredContent" {
                let featured = makeFeaturedContentView(for: task, isCurrentDay: isCurrentDay)
                featured.isUserInteractionEnabled = isCurrentDay
                featured.alpha = isCurrentDay ? 1.0 : 0.4
                listViewController.appendView(featured, animated: true)
                continue
            }
            let cards = taskViewControllers(task, on: date) ?? {
                var q = OCKEventQuery(for: date)
                q.taskIDs = [task.id]
                return [OCKInstructionsTaskViewController(query: q, store: store)]
            }()

            for card in cards {
                if let carekitView = card.view as? OCKView {
                    carekitView.customStyle = style
                }

                card.view.isUserInteractionEnabled = isCurrentDay
                card.view.alpha = isCurrentDay ? 1.0 : 0.4

                listViewController.appendViewController(card, animated: true)
            }
        }

        isLoading = false
    }
    private func makeFeaturedContentView(for task: any OCKAnyTask, isCurrentDay: Bool) -> UIView {
        let featured = OCKFeaturedContentView()
        featured.customStyle = style
        
        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 0
        
        let detailLabel = UILabel()
        detailLabel.font = .preferredFont(forTextStyle: .subheadline)
        detailLabel.numberOfLines = 0
        
        if let t = task as? OCKTask {
            titleLabel.text = t.title
            detailLabel.text = t.instructions
        } else {
            titleLabel.text = task.id
            detailLabel.text = nil
        }
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        featured.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: featured.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: featured.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: featured.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: featured.bottomAnchor, constant: -16)
        ])
        
        featured.isUserInteractionEnabled = isCurrentDay
        featured.alpha = isCurrentDay ? 1.0 : 0.4
        return featured
    }
}
extension View {
    func formattedHostingController() -> UIHostingController<Self> {
        let vc = UIHostingController(rootView: self)
        vc.view.backgroundColor = .clear
        return vc
    }
}
