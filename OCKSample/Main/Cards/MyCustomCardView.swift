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
