//
//  InsightsView.swift
//  OCKSample
//
//  Created by Corey Baker on 4/17/25.
//  Updated by You on 2/21/26.
//

import CareKit
import CareKitEssentials
import CareKitStore
import CareKitUI
import SwiftUI
struct InsightsView: View {

    @CareStoreFetchRequest(query: query()) private var events
    @State private var intervalSelected = 1 // Default to week
    @State private var chartInterval = DateInterval()
    @State private var period: PeriodComponent = .day
    @State private var sortedTaskIDs: [String: Int] = [:]
    var body: some View {
        NavigationStack {
            dateIntervalSegmentView
                .padding()
            ScrollView {
                VStack {
                    let ordered = orderedEvents
                    ForEach(ordered.indices, id: \.self) { idx in
                        let fetched = ordered[idx]
                        let eventResult = fetched.result
                        let dataStrategy = determineDataStrategy(for: eventResult.task.id)
                        let meanGradientStart = Color(TintColorFlipKey.defaultValue)
                        let meanGradientEnd = Color.accentColor
                        let meanConfiguration = CKEDataSeriesConfiguration(
                            taskID: eventResult.task.id,
                            dataStrategy: dataStrategy,
                            mark: .bar,
                            legendTitle: "AVERAGE",
                            showMarkWhenHighlighted: true,
                            showMeanMark: false,
                            showMedianMark: false,
                            color: meanGradientEnd,
                            gradientStartColor: meanGradientStart
                        ) { event in
                            event.computeProgress(by: .maxOutcomeValue())
                        }
                        let sumConfiguration = CKEDataSeriesConfiguration(
                            taskID: eventResult.task.id,
                            dataStrategy: .sum,
                            mark: .bar,
                            legendTitle: "TOTAL",
                            color: Color(TintColorFlipKey.defaultValue)
                        ) { event in
                            event.computeProgress(by: .maxOutcomeValue())
                        }
                        CareKitEssentialChartView(
                            title: eventResult.title,
                            subtitle: subtitle,
                            dateInterval: $chartInterval,
                            period: $period,
                            configurations: [
                                meanConfiguration,
                                sumConfiguration
                            ]
                        )
                    }
                }
                .padding()
            }
            .onAppear {
                let taskIDs = TaskID.ordered
                sortedTaskIDs = computeTaskIDOrder(taskIDs: taskIDs)
                events.query.taskIDs = taskIDs
                events.query.dateInterval = eventQueryInterval
                setupChartPropertiesForSegmentSelection(intervalSelected)
            }
            #if os(iOS)
            .onChange(of: intervalSelected) { _, newValue in
                setupChartPropertiesForSegmentSelection(newValue)
            }
            #else
            .onChange(of: intervalSelected, initial: true) { _, newValue in
                setupChartPropertiesForSegmentSelection(newValue)
            }
            #endif
        }
    }
    private var orderedEvents: [CareStoreFetchedResult<OCKAnyEvent>] {
        events.latest.sorted { left, right in
            let l = left.result.task.id
            let r = right.result.task.id
            return (sortedTaskIDs[l] ?? 0) < (sortedTaskIDs[r] ?? 0)
        }
    }
    private var dateIntervalSegmentView: some View {
        Picker("CHOOSE_DATE_INTERVAL", selection: $intervalSelected.animation()) {
            Text("TODAY").tag(0)
            Text("WEEK").tag(1)
            Text("MONTH").tag(2)
            Text("YEAR").tag(3)
        }
        #if !os(watchOS)
        .pickerStyle(.segmented)
        #else
        .pickerStyle(.automatic)
        #endif
    }
    private var subtitle: String {
        switch intervalSelected {
        case 0: return "TODAY"
        case 1: return "WEEK"
        case 2: return "MONTH"
        case 3: return "YEAR"
        default: return "WEEK"
        }
    }
    private var eventQueryInterval: DateInterval {
        // Fetch enough events to build task list + charts
        Calendar.current.dateInterval(of: .weekOfYear, for: Date())!
    }

    private func determineDataStrategy(for taskID: String) -> CKEDataSeriesConfiguration.DataStrategy {
        switch taskID {
        case TaskID.steps:
            return .max
        default:
            return .mean
        }
    }
    private func setupChartPropertiesForSegmentSelection(_ segmentValue: Int) {
        let now = Date()
        let calendar = Calendar.current
        switch segmentValue {
        case 0:
            let start = calendar.startOfDay(for: now)
            period = .day
            chartInterval = DateInterval(start: start, end: now)
        case 1:
            let start = calendar.date(byAdding: .day, value: -7, to: now)!
            period = .week
            chartInterval = DateInterval(start: start, end: now)
        case 2:
            let start = calendar.date(byAdding: .month, value: -1, to: now)!
            period = .month
            chartInterval = DateInterval(start: start, end: now)
        case 3:
            let start = calendar.date(byAdding: .year, value: -1, to: now)!
            period = .month
            chartInterval = DateInterval(start: start, end: now)
        default:
            let start = calendar.date(byAdding: .day, value: -7, to: now)!
            period = .week
            chartInterval = DateInterval(start: start, end: now)
        }
    }
    private func computeTaskIDOrder(taskIDs: [String]) -> [String: Int] {
        taskIDs.enumerated().reduce(into: [String: Int]()) { dict, pair in
            dict[pair.element] = pair.offset
        }
    }
    static func query() -> OCKEventQuery {
        OCKEventQuery(dateInterval: .init())
    }
}
#Preview {
    InsightsView()
        .environment(\.careStore, Utility.createPreviewStore())
        .careKitStyle(Styler())
}
