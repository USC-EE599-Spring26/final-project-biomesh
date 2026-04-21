//
//  MyCustomCardView.swift
//  OCKSample
//
//  Created by Corey Baker on 3/10/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKitEssentials
import CareKit
import CareKitStore
import CareKitUI
import os.log
#if canImport(ResearchKit) && canImport(ResearchKitUI)
import ResearchKit
import ResearchKitActiveTask
import ResearchKitUI
#endif
import SwiftUI

struct MyCustomCardView: CareKitEssentialView {
    @Environment(\.careStore) var store
    @Environment(\.customStyler) var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    let event: OCKAnyEvent

    @State private var noCaffeineChecked = false
    @State private var dimLightsChecked = false
    @State private var phoneFaceDownChecked = false
    @State private var isSaving = false

    private static let checklistItems = [
        "No caffeine after 2 PM",
        "Dim lights 30 min before sleep",
        "Put your phone face-down"
    ]

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                InformationHeaderView(
                    title: Text(event.title),
                    information: event.detailText,
                    event: event
                )

                Divider()

                checkboxRow(
                    label: Self.checklistItems[0],
                    isChecked: $noCaffeineChecked,
                    icon: "cup.and.saucer"
                )
                checkboxRow(
                    label: Self.checklistItems[1],
                    isChecked: $dimLightsChecked,
                    icon: "lightbulb"
                )
                checkboxRow(
                    label: Self.checklistItems[2],
                    isChecked: $phoneFaceDownChecked,
                    icon: "iphone.gen3.slash"
                )

                VStack(alignment: .center) {
                    HStack(alignment: .center) {
                        Button(action: {
                            saveChecklist()
                        }) {
                            RectangularCompletionView(
                                isComplete: isComplete
                            ) {
                                Spacer()
                                Text(buttonText)
                                    .foregroundColor(foregroundColor)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                Spacer()
                            }
                        }
                        .buttonStyle(NoHighlightStyle())
                        .disabled(isComplete || !hasCheckedItem || isSaving)
                    }
                }
            }
            .padding(isCardEnabled ? [.all] : [])
        }
        .careKitStyle(style)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .onAppear {
            syncStateFromOutcome()
        }
        .onChange(of: outcomeSignature) { _, _ in
            syncStateFromOutcome()
        }
    }

    @ViewBuilder
    private func checkboxRow(
        label: String,
        isChecked: Binding<Bool>,
        icon: String
    ) -> some View {
        Button(action: {
            guard !isComplete else { return }
            isChecked.wrappedValue.toggle()
        }) {
            HStack(spacing: 12) {
                Image(systemName: isChecked.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isChecked.wrappedValue ? .accentColor : .gray)
                    .font(.title3)

                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 24)

                Text(label)
                    .foregroundColor(.primary)

                Spacer()
            }
        }
        .buttonStyle(.plain)
        .disabled(isComplete || isSaving)
    }

    private var savedKinds: Set<String> {
        Set((event.outcome?.values ?? []).compactMap(\.kind))
    }

    private var outcomeSignature: String {
        savedKinds.sorted().joined(separator: "|")
    }

    private var isComplete: Bool {
        !savedKinds.isEmpty
    }

    private var hasCheckedItem: Bool {
        noCaffeineChecked || dimLightsChecked || phoneFaceDownChecked
    }

    private var buttonText: LocalizedStringKey {
        isComplete ? "COMPLETED" : "MARK_COMPLETE"
    }

    private var foregroundColor: Color {
        isComplete ? .accentColor : .white
    }

    private func syncStateFromOutcome() {
        let kinds = savedKinds
        noCaffeineChecked = kinds.contains("noCaffeine")
        dimLightsChecked = kinds.contains("dimLights")
        phoneFaceDownChecked = kinds.contains("phoneFaceDown")
    }

    private func saveChecklist() {
        guard !isComplete else { return }

        Task {
            isSaving = true
            defer { isSaving = false }

            do {
                var outcomeValues = [OCKOutcomeValue]()

                if noCaffeineChecked {
                    var value = OCKOutcomeValue(1)
                    value.kind = "noCaffeine"
                    outcomeValues.append(value)
                }

                if dimLightsChecked {
                    var value = OCKOutcomeValue(1)
                    value.kind = "dimLights"
                    outcomeValues.append(value)
                }

                if phoneFaceDownChecked {
                    var value = OCKOutcomeValue(1)
                    value.kind = "phoneFaceDown"
                    outcomeValues.append(value)
                }

                let updatedOutcome = try await saveOutcomeValues(
                    outcomeValues,
                    event: event
                )

                Logger.myCustomCardView.info(
                    "Saved wind-down outcomes: \(updatedOutcome.values)"
                )

                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        .init(name: Notification.Name(rawValue: Constants.shouldRefreshView))
                    )
                }
            } catch {
                Logger.myCustomCardView.info(
                    "Error saving wind-down values: \(error)"
                )
            }
        }
    }
}

#if !os(watchOS)
extension MyCustomCardView: EventViewable {
    public init?(
        event: OCKAnyEvent,
        store: any OCKAnyStoreProtocol
    ) {
        self.init(event: event)
    }
}
#endif

struct FeaturedTaskCardView: CareKitEssentialView {
    @Environment(\.careStore) var store
    @Environment(\.customStyler) var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    let event: OCKAnyEvent
    @State private var isSaving = false

    private var assetName: String {
        (event.task as? OCKTask)?.asset ?? "star.fill"
    }

    private var instructions: String? {
        (event.task as? OCKTask)?.instructions
    }

    private var isComplete: Bool {
        !(event.outcome?.values.isEmpty ?? true)
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: assetName)
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 76, height: 76)
                        .background(
                            LinearGradient(
                                colors: [.accentColor, .accentColor.opacity(0.55)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        InformationHeaderView(
                            title: Text(event.title),
                            information: event.detailText,
                            event: event
                        )

                        if let instructions, !instructions.isEmpty {
                            Text(instructions)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Button(action: saveCompletion) {
                    RectangularCompletionView(isComplete: isComplete) {
                        Text(isComplete ? "Completed" : "Mark Featured Task Complete")
                            .fontWeight(.semibold)
                            .foregroundStyle(isComplete ? Color.accentColor : .white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .buttonStyle(NoHighlightStyle())
                .disabled(isComplete || isSaving)
            }
            .padding(isCardEnabled ? [.all] : [])
        }
        .careKitStyle(style)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    private func saveCompletion() {
        guard !isComplete else { return }

        Task {
            isSaving = true
            defer { isSaving = false }

            do {
                var value = OCKOutcomeValue(1)
                value.kind = "featuredComplete"
                _ = try await saveOutcomeValues([value], event: event)

                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        .init(name: Notification.Name(rawValue: Constants.shouldRefreshView))
                    )
                }
            } catch {
                Logger.myCustomCardView.info("Error saving featured task: \(error)")
            }
        }
    }
}

#if !os(watchOS)
extension FeaturedTaskCardView: EventViewable {
    public init?(
        event: OCKAnyEvent,
        store: any OCKAnyStoreProtocol
    ) {
        self.init(event: event)
    }
}
#endif

#if !os(watchOS) && canImport(ResearchKit) && canImport(ResearchKitUI)
struct ActiveSurveyTaskCardView: CareKitEssentialView {
    @Environment(\.careStore) var store
    @Environment(\.customStyler) var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    let event: OCKAnyEvent
    @State private var isPresentingSurvey = false
    @State private var isSaving = false

    private var task: OCKTask? {
        event.task as? OCKTask
    }

    private var surveyType: Survey? {
        task?.uiKitSurvey
    }

    private var isComplete: Bool {
        !(event.outcome?.values.isEmpty ?? true)
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                InformationHeaderView(
                    title: Text(event.title),
                    information: event.detailText,
                    event: event
                )

                Divider()

                if let summaryText {
                    Text(summaryText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button(action: {
                    isPresentingSurvey = true
                }) {
                    RectangularCompletionView(isComplete: isComplete) {
                        Text(isComplete ? "Completed" : "Begin")
                            .fontWeight(.semibold)
                            .foregroundStyle(isComplete ? Color.accentColor : .white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .buttonStyle(NoHighlightStyle())
                .disabled(isComplete || isSaving || surveyType == nil)
            }
            .padding(isCardEnabled ? [.all] : [])
        }
        .careKitStyle(style)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .sheet(isPresented: $isPresentingSurvey) {
            if let surveyType {
                let survey = surveyType.type()
                ResearchKitTaskPresenter(
                    task: survey.createSurvey(),
                    extractOutcome: survey.extractAnswers
                ) { values in
                    saveSurveyOutcome(values)
                }
            }
        }
    }

    private var summaryText: String? {
        guard let outcome = event.outcome else {
            return task?.instructions
        }

        let values = outcome.values
        guard !values.isEmpty else {
            return task?.instructions
        }

        if let total = values.first(where: { $0.kind == "totalTapCount" })?.integerValue {
            return "Total taps: \(total)"
        }
        if let range = values.first(where: { $0.kind == #keyPath(ORKRangeOfMotionResult.range) })?.doubleValue {
            return "Range of Motion: \(Int(range))°"
        }
        return "Result recorded."
    }

    private func saveSurveyOutcome(_ values: [OCKOutcomeValue]) {
        guard !values.isEmpty else { return }

        Task {
            isSaving = true
            defer { isSaving = false }

            do {
                _ = try await saveOutcomeValues(values, event: event)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        .init(name: Notification.Name(rawValue: Constants.shouldRefreshView))
                    )
                }
            } catch {
                Logger.myCustomCardView.info("Error saving active survey task: \(error)")
            }
        }
    }
}

extension ActiveSurveyTaskCardView: EventViewable {
    public init?(
        event: OCKAnyEvent,
        store: any OCKAnyStoreProtocol
    ) {
        self.init(event: event)
    }
}

private struct ResearchKitTaskPresenter: UIViewControllerRepresentable {
    let task: ORKTask
    let extractOutcome: (ORKTaskResult) -> [OCKOutcomeValue]?
    let onComplete: ([OCKOutcomeValue]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(extractOutcome: extractOutcome, onComplete: onComplete)
    }

    func makeUIViewController(context: Context) -> ORKTaskViewController {
        let controller = ORKTaskViewController(task: task, taskRun: nil)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(
        _ uiViewController: ORKTaskViewController,
        context: Context
    ) {}

    final class Coordinator: NSObject, @MainActor ORKTaskViewControllerDelegate {
        let extractOutcome: (ORKTaskResult) -> [OCKOutcomeValue]?
        let onComplete: ([OCKOutcomeValue]) -> Void

        init(
            extractOutcome: @escaping (ORKTaskResult) -> [OCKOutcomeValue]?,
            onComplete: @escaping ([OCKOutcomeValue]) -> Void
        ) {
            self.extractOutcome = extractOutcome
            self.onComplete = onComplete
        }

        func taskViewController(
            _ taskViewController: ORKTaskViewController,
            didFinishWith reason: ORKTaskFinishReason,
            error: (any Error)?
        ) {
            if reason == .completed,
               let values = extractOutcome(taskViewController.result) {
                onComplete(values)
            }
            taskViewController.dismiss(animated: true)
        }
    }
}
#endif

struct GridTaskCardView: CareKitEssentialView {
    @Environment(\.careStore) var store
    @Environment(\.customStyler) var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    let event: OCKAnyEvent
    @State private var isSaving = false

    private let options = [
        ("Low", "1.circle.fill", 1),
        ("Medium", "2.circle.fill", 2),
        ("High", "3.circle.fill", 3),
        ("Done", "checkmark.circle.fill", 4)
    ]

    private var selectedValue: Int? {
        event.outcome?.values.compactMap(\.integerValue).first
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                InformationHeaderView(
                    title: Text(event.title),
                    information: event.detailText,
                    event: event
                )

                Divider()

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(options, id: \.0) { option in
                        Button {
                            saveSelection(option.2)
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: option.1)
                                    .font(.title2)
                                Text(option.0)
                                    .font(.subheadline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        selectedValue == option.2
                                            ? Color.accentColor.opacity(0.16)
                                            : Color.gray.opacity(0.08)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(
                                        selectedValue == option.2
                                            ? Color.accentColor
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedValue != nil || isSaving)
                    }
                }

                if let selectedValue {
                    Text("Selected value: \(selectedValue)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(isCardEnabled ? [.all] : [])
        }
        .careKitStyle(style)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    private func saveSelection(_ score: Int) {
        guard selectedValue == nil else { return }

        Task {
            isSaving = true
            defer { isSaving = false }

            do {
                var value = OCKOutcomeValue(score)
                value.kind = "gridSelection"
                _ = try await saveOutcomeValues([value], event: event)

                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        .init(name: Notification.Name(rawValue: Constants.shouldRefreshView))
                    )
                }
            } catch {
                Logger.myCustomCardView.info("Error saving grid task: \(error)")
            }
        }
    }
}

#if !os(watchOS)
extension GridTaskCardView: EventViewable {
    public init?(
        event: OCKAnyEvent,
        store: any OCKAnyStoreProtocol
    ) {
        self.init(event: event)
    }
}
#endif

struct StandardNumericProgressCardView: CareKitEssentialView {
    @Environment(\.careStore) var store
    @Environment(\.customStyler) var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    let event: OCKAnyEvent
    @State private var isSaving = false

    private var progress: Int {
        event.outcome?.values.compactMap(\.integerValue).first ?? 0
    }

    private var isComplete: Bool {
        progress > 0
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                InformationHeaderView(
                    title: Text(event.title),
                    information: event.detailText,
                    event: event
                )

                Divider()

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(progress)")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(Color.accentColor)
                        Text("Progress")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("1")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.secondary)
                        Text("Goal")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                ProgressView(value: Double(min(progress, 1)), total: 1)

                Button(action: saveProgress) {
                    RectangularCompletionView(isComplete: isComplete) {
                        Text(isComplete ? "Completed" : "Add Progress")
                            .fontWeight(.semibold)
                            .foregroundStyle(isComplete ? Color.accentColor : .white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .buttonStyle(NoHighlightStyle())
                .disabled(isComplete || isSaving)
            }
            .padding(isCardEnabled ? [.all] : [])
        }
        .careKitStyle(style)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    private func saveProgress() {
        guard !isComplete else { return }

        Task {
            isSaving = true
            defer { isSaving = false }

            do {
                var value = OCKOutcomeValue(1)
                value.kind = "progress"
                _ = try await saveOutcomeValues([value], event: event)

                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        .init(name: Notification.Name(rawValue: Constants.shouldRefreshView))
                    )
                }
            } catch {
                Logger.myCustomCardView.info("Error saving numeric progress task: \(error)")
            }
        }
    }
}

#if !os(watchOS)
extension StandardNumericProgressCardView: EventViewable {
    public init?(
        event: OCKAnyEvent,
        store: any OCKAnyStoreProtocol
    ) {
        self.init(event: event)
    }
}
#endif

struct StandardLabeledValueCardView: View {
    @Environment(\.customStyler) var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    let event: OCKAnyEvent

    private var latestValue: String {
        guard let value = event.outcome?.values.first else {
            return "Incomplete"
        }

        if let stringValue = value.stringValue, !stringValue.isEmpty {
            return stringValue
        }
        if let intValue = value.integerValue {
            return "\(intValue)"
        }
        if let doubleValue = value.doubleValue {
            return String(format: "%.1f", doubleValue)
        }
        if let boolValue = value.booleanValue {
            return boolValue ? "Yes" : "No"
        }
        return "Recorded"
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                InformationHeaderView(
                    title: Text(event.title),
                    information: event.detailText,
                    event: event
                )

                Divider()

                HStack {
                    Text("Latest Value")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(latestValue)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(event.outcome == nil ? Color.secondary : Color.primary)
                }
            }
            .padding(isCardEnabled ? [.all] : [])
        }
        .careKitStyle(style)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
}

#if !os(watchOS)
extension StandardLabeledValueCardView: EventViewable {
    public init?(
        event: OCKAnyEvent,
        store: any OCKAnyStoreProtocol
    ) {
        self.init(event: event)
    }
}
#endif

struct MyCustomCardView_Previews: PreviewProvider {
    static var store = Utility.createPreviewStore()

    static var query: OCKEventQuery {
        var query = OCKEventQuery(for: Date())
        query.taskIDs = [TaskID.sleepHygiene]
        return query
    }

    static var previews: some View {
        VStack {
            @CareStoreFetchRequest(query: query) var events
            if let event = events.latest.first {
                MyCustomCardView(event: event.result)
            }
        }
        .environment(\.careStore, store)
        .padding()
    }
}
