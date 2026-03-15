//
//  MyCustomCardView.swift
//  OCKSample
//
//  Created by Alarik Damrow on 3/15/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitEssentials
import CareKitStore
import CareKitUI
import os.log
import SwiftUI

struct MyCustomCardView: CareKitEssentialView {

    @Environment(\.careStore) var store
    @Environment(\.customStyler) private var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    let event: OCKAnyEvent

    var body: some View {
        CardView {
            VStack(alignment: .leading) {
                InformationHeaderView(
                    title: Text(event.title),
                    information: event.detailText,
                    event: event
                )

                event.instructionsText
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical)

                VStack(alignment: .center) {
                    HStack(alignment: .center) {
                        Button {
                            toggleEventCompletion()
                        } label: {
                            RectangularCompletionView(isComplete: isComplete) {
                                Spacer()

                                Text(buttonText)
                                    .foregroundColor(foregroundColor)
                                    .frame(maxWidth: .infinity)
                                    .padding()

                                Spacer()
                            }
                        }
                    }
                    .buttonStyle(NoHighlightStyle())
                }
            }
            .padding(isCardEnabled ? .all : [])
        }
        .careKitStyle(style)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    private var isComplete: Bool {
        event.isComplete
    }

    private var buttonText: LocalizedStringKey {
        isComplete ? "COMPLETED" : "START_SURVEY"
    }

    private var foregroundColor: Color {
        isComplete ? .accentColor : .white
    }

    private func toggleEventCompletion() {
        Task {
            do {
                if event.isComplete {
                    let updatedOutcome = try await saveOutcomeValues([], event: event)
                    Logger.myCustomCardView.info(
                        "Updated event by removing outcome values: \(updatedOutcome.values)"
                    )
                } else {
                    let newOutcomeValue = OCKOutcomeValue(true)
                    let updatedOutcome = try await saveOutcomeValues(
                        [newOutcomeValue],
                        event: event
                    )
                    Logger.myCustomCardView.info(
                        "Updated event by setting outcome values: \(updatedOutcome.values)"
                    )
                }
            } catch {
                Logger.myCustomCardView.error(
                    "Error saving value: \(error.localizedDescription)"
                )
            }
        }
    }
}

#if !os(watchOS)
extension MyCustomCardView: EventViewable {
    init?(
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
