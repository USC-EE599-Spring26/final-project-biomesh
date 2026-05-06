//
//  WatchCareListView.swift
//  OCKSample
//
//  Created by Alarik Damrow on 5/2/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
import CareKitStore
import ParseSwift

struct WatchCareListView: View {
    @Environment(\.appDelegate) private var appDelegate

    @State private var events: [OCKAnyEvent] = []
    @State private var isLoading = false
    @State private var statusText = "Loading daily logs..."

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if isLoading {
                        ProgressView("Loading")
                            .padding(.top, 20)
                    } else if events.isEmpty {
                        Text(statusText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()

                        Button("Refresh") {
                            Task {
                                await loadTodayTasks()
                            }
                        }
                    } else {
                        ForEach(events.indices, id: \.self) { index in
                            WatchDailyLogCard(
                                event: events[index],
                                onLogValue: { amount in
                                    Task {
                                        await logValue(amount, for: events[index])
                                    }
                                },
                                onComplete: {
                                    Task {
                                        await completeEvent(events[index])
                                    }
                                }
                            )
                        }

                        Button("Refresh") {
                            Task {
                                await loadTodayTasks()
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
            .navigationTitle("Daily Logs")
            .task {
                await loadTodayTasks()
            }
        }
    }

    @MainActor
    private func loadTodayTasks() async {
        isLoading = true
        statusText = "Loading daily logs..."
        defer { isLoading = false }

        guard (try? await User.current()) != nil else {
            statusText = "Sign in from Profile first"
            events = []
            return
        }

        guard let appDelegate else {
            statusText = "Missing app delegate"
            events = []
            return
        }

        do {
            guard let store = try await readyStore(from: appDelegate) else {
                statusText = "CareKit store not ready"
                events = []
                return
            }

            await synchronizeOnBackground(store)

            var query = OCKEventQuery(for: Date())
            query.taskIDs = TaskID.orderedWatchOS

            let fetchedEvents = try await store.fetchAnyEvents(query: query)

            var seenTaskIDs = Set<String>()
            events = fetchedEvents
                .filter { TaskID.orderedWatchOS.contains($0.task.id) }
                .sorted {
                    taskPriority($0.task.id) < taskPriority($1.task.id)
                }
                .filter { seenTaskIDs.insert($0.task.id).inserted }

            statusText = events.isEmpty ? "No daily logs for today" : ""

        } catch {
            statusText = "Could not load daily logs"
            events = []
            print("Watch daily log load failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func logValue(_ amount: Double, for event: OCKAnyEvent) async {
        guard let appDelegate else {
            statusText = "Missing app delegate"
            return
        }

        do {
            guard let store = try await readyStore(from: appDelegate) else {
                statusText = "CareKit store not ready"
                return
            }

            var value = OCKOutcomeValue(amount)
            value.kind = valueKind(for: event.task.id)
            value.createdDate = Date()

            if var existingOutcome = event.outcome {
                existingOutcome.values.append(value)
                _ = try await store.updateAnyOutcome(existingOutcome)
            } else {
                var outcome = OCKOutcome(
                    taskUUID: event.task.uuid,
                    taskOccurrenceIndex: event.scheduleEvent.occurrence,
                    values: [value]
                )
                outcome.effectiveDate = event.scheduleEvent.start

                _ = try await store.addAnyOutcome(outcome)
            }

            await synchronizeOnBackground(store)
            await loadTodayTasks()

        } catch {
            statusText = "Could not log value"
            print("Watch log value failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func completeEvent(_ event: OCKAnyEvent) async {
        guard let appDelegate else {
            statusText = "Missing app delegate"
            return
        }

        do {
            guard let store = try await readyStore(from: appDelegate) else {
                statusText = "CareKit store not ready"
                return
            }

            var value = OCKOutcomeValue(1)
            value.kind = "watchComplete"
            value.createdDate = Date()

            if var existingOutcome = event.outcome {
                existingOutcome.values.append(value)
                _ = try await store.updateAnyOutcome(existingOutcome)
            } else {
                var outcome = OCKOutcome(
                    taskUUID: event.task.uuid,
                    taskOccurrenceIndex: event.scheduleEvent.occurrence,
                    values: [value]
                )
                outcome.effectiveDate = event.scheduleEvent.start

                _ = try await store.addAnyOutcome(outcome)
            }

            await synchronizeOnBackground(store)
            await loadTodayTasks()

        } catch {
            statusText = "Could not complete task"
            print("Watch task completion failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func readyStore(from appDelegate: AppDelegate) async throws -> OCKStore? {
        if let store = appDelegate.store,
           store.name != Constants.noCareStoreName {
            return store
        }

        let remoteUUID = try await Utility.getRemoteClockUUID()
        try await appDelegate.setupRemotes(uuid: remoteUUID)

        guard let store = appDelegate.store else {
            return nil
        }

        appDelegate.parseRemote?.automaticallySynchronizes = true
        await synchronizeOnBackground(store)

        return store
    }

    private func taskPriority(_ taskID: String) -> Int {
        TaskID.orderedWatchOS.firstIndex(of: taskID) ?? Int.max
    }

    private func synchronizeOnBackground(_ store: OCKStore) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                store.synchronize { _ in
                    continuation.resume()
                }
            }
        }
    }

    private func valueKind(for taskID: String) -> String {
        switch taskID {
        case TaskID.caffeineIntake:
            return "caffeineMg"
        case TaskID.waterIntake:
            return "waterOz"
        case TaskID.anxietyCheck:
            return "anxiety"
        default:
            return "watchLog"
        }
    }
}

// MARK: - Watch Daily Log Card

private struct WatchDailyLogCard: View {
    let event: OCKAnyEvent
    let onLogValue: (Double) -> Void
    let onComplete: () -> Void

    @State private var amount: Double = 0

    private var isSliderLog: Bool {
        event.task.id == TaskID.caffeineIntake ||
        event.task.id == TaskID.waterIntake
    }

    private var isComplete: Bool {
        !(event.outcome?.values.isEmpty ?? true)
    }

    private var unit: String {
        switch event.task.id {
        case TaskID.caffeineIntake:
            return "mg"
        case TaskID.waterIntake:
            return "fl oz"
        default:
            return ""
        }
    }

    private var sliderRange: ClosedRange<Double> {
        switch event.task.id {
        case TaskID.caffeineIntake:
            return 0...400
        case TaskID.waterIntake:
            return 0...32
        default:
            return 0...10
        }
    }

    private var sliderStep: Double {
        switch event.task.id {
        case TaskID.caffeineIntake:
            return 8
        case TaskID.waterIntake:
            return 4
        default:
            return 1
        }
    }

    private var defaultAmount: Double {
        switch event.task.id {
        case TaskID.caffeineIntake:
            return 8
        case TaskID.waterIntake:
            return 4
        default:
            return 1
        }
    }

    private var subtitle: String {
        if let text = event.scheduleEvent.element.text, !text.isEmpty {
            return text
        }

        return "Any time today"
    }

    private var latestLoggedValueText: String? {
        guard let latest = event.outcome?.values.last else {
            return nil
        }

        if let doubleValue = latest.doubleValue {
            return "\(Int(doubleValue)) \(unit)"
        }

        if let intValue = latest.integerValue {
            return "\(intValue) \(unit)"
        }

        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(event.title)
                        .font(.headline)
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            Divider()

            if isSliderLog {
                HStack {
                    Text("Amount")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(amount)) \(unit)")
                        .font(.headline)
                }

                Slider(
                    value: $amount,
                    in: sliderRange,
                    step: sliderStep
                )

                quickAmountButtons

                Button {
                    onLogValue(amount)
                } label: {
                    Label("Log \(Int(amount)) \(unit)", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if let latestLoggedValueText {
                    Text("Latest: \(latestLoggedValueText)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

            } else {
                Button {
                    guard !isComplete else { return }
                    onComplete()
                } label: {
                    Label(
                        isComplete ? "Completed" : "Mark Complete",
                        systemImage: isComplete ? "checkmark.circle.fill" : "circle"
                    )
                    .frame(maxWidth: .infinity)
                }
                .disabled(isComplete)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            amount = latestAmountOrDefault()
        }
    }

    @ViewBuilder
    private var quickAmountButtons: some View {
        if event.task.id == TaskID.caffeineIntake {
            HStack(spacing: 6) {
                quickButton("\u{1F375}", "47", 47)
                quickButton("\u{2615}", "95", 95)
                quickButton("\u{2615}\u{2615}", "190", 190)
                quickButton("\u{26A1}", "80", 80)
            }
        } else if event.task.id == TaskID.waterIntake {
            HStack(spacing: 6) {
                quickButton("\u{1F95B}", "8", 8)
                quickButton("\u{1F4A7}", "16", 16)
                quickButton("\u{1FAD7}", "24", 24)
            }
        }
    }

    private func quickButton(_ icon: String, _ label: String, _ value: Double) -> some View {
        Button {
            amount = value
        } label: {
            VStack(spacing: 2) {
                Text(icon)
                    .font(.body)
                Text(label)
                    .font(.system(size: 10))
            }
        }
        .buttonStyle(.bordered)
    }

    private func latestAmountOrDefault() -> Double {
        guard let latest = event.outcome?.values.last else {
            return defaultAmount
        }

        if let doubleValue = latest.doubleValue {
            return doubleValue
        }

        if let intValue = latest.integerValue {
            return Double(intValue)
        }

        return defaultAmount
    }
}
