//
//  CareView.swift
//  OCKWatchSample Extension
//
//  Created by Corey Baker on 6/25/20.
//  Updated by You on 2/21/26.
//

import CareKit
import CareKitEssentials
import CareKitStore
import CareKitUI
import SwiftUI

struct CareView: View {

    @CareStoreFetchRequest(query: query()) private var events
    @State private var sortedTaskIDs: [String: Int] = [:]

    var body: some View {
        ScrollView {
            let ordered = orderedEvents

            // Use indices so we don't require Identifiable conformance
            ForEach(ordered.indices, id: \.self) { idx in
                let event = ordered[idx]

                // Pick a card style by task id
                if event.result.task.id == TaskID.steps {
                    SimpleTaskView(event: event)
                } else {
                    InstructionsTaskView(event: event)
                }
            }
        }
        .onAppear {
            let taskIDs = TaskID.orderedWatchOS
            sortedTaskIDs = computeTaskIDOrder(taskIDs: taskIDs)
            events.query.taskIDs = taskIDs
        }
    }

    private var orderedEvents: [CareStoreFetchedResult<OCKAnyEvent>] {
        events.latest.sorted { left, right in
            let l = left.result.task.id
            let r = right.result.task.id
            return (sortedTaskIDs[l] ?? 0) < (sortedTaskIDs[r] ?? 0)
        }
    }

    static func query() -> OCKEventQuery {
        OCKEventQuery(for: Date())
    }

    private func computeTaskIDOrder(taskIDs: [String]) -> [String: Int] {
        taskIDs.enumerated().reduce(into: [:]) { dict, pair in
            dict[pair.element] = pair.offset
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CareView()
            .environment(\.careStore, Utility.createPreviewStore())
            .careKitStyle(Styler())
    }
}
