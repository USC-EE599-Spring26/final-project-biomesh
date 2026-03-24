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
import SwiftUI

// We use `CareKitEssentialView` to help us with saving
// new events.
struct MyCustomCardView: CareKitEssentialView {
    @Environment(\.careStore) var store
    @Environment(\.customStyler) var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    let event: OCKAnyEvent

    @State private var noCaffeineChecked = false
    @State private var dimLightsChecked = false
    @State private var phoneFaceDownChecked = false

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
                        .disabled(!allChecked && !isComplete)
                    }
                }
            }
            .padding(isCardEnabled ? [.all] : [])
        }
        .careKitStyle(style)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .onAppear {
            loadExistingOutcomes()
        }
    }

    @ViewBuilder
    private func checkboxRow(
        label: String,
        isChecked: Binding<Bool>,
        icon: String
    ) -> some View {
        Button(action: {
            if !isComplete {
                isChecked.wrappedValue.toggle()
            }
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
        .disabled(isComplete)
    }

    private var isComplete: Bool {
        event.isComplete
    }

    private var allChecked: Bool {
        noCaffeineChecked && dimLightsChecked && phoneFaceDownChecked
    }

    private var buttonText: LocalizedStringKey {
        if isComplete {
            return "COMPLETED"
        }
        return allChecked ? "MARK_COMPLETE" : "MARK_COMPLETE"
    }

    private var foregroundColor: Color {
        isComplete ? .accentColor : .white
    }

    private func loadExistingOutcomes() {
        guard let values = event.outcome?.values else { return }
        for value in values {
            if let kind = value.kind {
                switch kind {
                case "noCaffeine": noCaffeineChecked = true
                case "dimLights": dimLightsChecked = true
                case "phoneFaceDown": phoneFaceDownChecked = true
                default: break
                }
            }
        }
    }

    private func saveChecklist() {
        Task {
            do {
                guard !isComplete else {
                    // Clear all outcome values
                    let updatedOutcome = try await saveOutcomeValues(
                        [],
                        event: event
                    )
                    noCaffeineChecked = false
                    dimLightsChecked = false
                    phoneFaceDownChecked = false
                    Logger.myCustomCardView.info(
                        "Cleared wind-down outcomes: \(updatedOutcome.values)"
                    )
                    return
                }

                // Save each checked item as a separate outcome value
                var outcomeValues = [OCKOutcomeValue]()

                if noCaffeineChecked {
                    var value = OCKOutcomeValue(true)
                    value.kind = "noCaffeine"
                    outcomeValues.append(value)
                }
                if dimLightsChecked {
                    var value = OCKOutcomeValue(true)
                    value.kind = "dimLights"
                    outcomeValues.append(value)
                }
                if phoneFaceDownChecked {
                    var value = OCKOutcomeValue(true)
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
        self.init(
            event: event
        )
    }
}

#endif

struct MyCustomCardView_Previews: PreviewProvider {
    static var store = Utility.createPreviewStore()
    static var query: OCKEventQuery {
        var query = OCKEventQuery(for: Date())
        query.taskIDs = [TaskID.caffeineIntake]
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
