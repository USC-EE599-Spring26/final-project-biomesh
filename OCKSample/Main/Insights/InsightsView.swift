//
//  InsightsView.swift
//  OCKSample
//
//  Created by Corey Baker on 4/17/25.
//  Copyright © 2025 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitEssentials
import CareKitStore
import CareKitUI
import SwiftUI

struct InsightsView: View {

	@CareStoreFetchRequest(query: query()) private var events
	@State var intervalSelected = 1
	@State var chartInterval = DateInterval()
	@State var period: PeriodComponent = .day
	@State var configurations: [CKEDataSeriesConfiguration] = []
	@State var sortedTaskIDs: [String: Int] = [:]

    var body: some View {
		NavigationStack {
			dateIntervalSegmentView
				.padding()
            ScrollView {
                VStack(spacing: 20) {

                    WeeklySummaryCardView(
                        events: allEvents,
                        dateInterval: chartInterval
                    )

                    CaffeineIntakeChartView(
                        events: allEvents,
                        dateInterval: chartInterval,
                        subtitle: subtitle
                    )

                    CaffeineAnxietyChartView(
                        events: allEvents,
                        dateInterval: chartInterval,
                        subtitle: subtitle
                    )

                    WindDownChartCardView(
                        events: allEvents,
                        dateInterval: chartInterval,
                        subtitle: subtitle
                    )
				}
				.padding()
			}
			.onAppear {
                let taskIDs = [
                    TaskID.caffeineIntake,
                    TaskID.anxietyCheck,
                    TaskID.sleepHygiene,
                    TaskID.waterIntake,
                    TaskID.heartRate,
                    TaskID.restingHeartRate,
                    TaskID.steps,
                    TaskID.sleepDuration,
                    TaskID.energySnapshot,
                    TaskID.stretchChecklist
                ]
				sortedTaskIDs = computeTaskIDOrder(taskIDs: taskIDs)
				events.query.taskIDs = taskIDs
                events.query.dateInterval = insightsFetchInterval
				setupChartPropertiesForSegmentSelection(intervalSelected)
			}
#if os(iOS)
			.onChange(of: intervalSelected) { _, intervalSegmentValue in
				setupChartPropertiesForSegmentSelection(intervalSegmentValue)
			}
#else
			.onChange(of: intervalSelected, initial: true) { _, newSegmentValue in
				setupChartPropertiesForSegmentSelection(newSegmentValue)
			}
#endif
		}
    }

    private var allEvents: [OCKAnyEvent] {
        events.latest.map(\.result)
    }

	private var dateIntervalSegmentView: some View {
		Picker(
			"CHOOSE_DATE_INTERVAL",
			selection: $intervalSelected.animation()
		) {
			Text("TODAY")
				.tag(0)
			Text("WEEK")
				.tag(1)
			Text("MONTH")
				.tag(2)
			Text("YEAR")
				.tag(3)
		}
		#if !os(watchOS)
		.pickerStyle(.segmented)
		#else
		.pickerStyle(.automatic)
		#endif
	}

	private var subtitle: String {
		switch intervalSelected {
		case 0:
			return String(localized: "TODAY")
		case 1:
			return String(localized: "WEEK")
		case 2:
			return String(localized: "MONTH")
		case 3:
			return String(localized: "YEAR")
		default:
			return String(localized: "WEEK")
		}
	}

    private var insightsFetchInterval: DateInterval {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(
            byAdding: .year,
            value: -1,
            to: now
        )!

        let startOfTomorrow = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: now)
        )!

        return DateInterval(start: startDate, end: startOfTomorrow)
    }

	private func setupChartPropertiesForSegmentSelection(_ segmentValue: Int) {
		let now = Date()
		let calendar = Calendar.current
		switch segmentValue {
		case 0:
			let startOfDay = Calendar.current.startOfDay(for: now)
			period = .day
			chartInterval = DateInterval(start: startOfDay, end: now)
		case 1:
			let startDate = calendar.date(byAdding: .weekday, value: -7, to: now)!
			period = .week
			chartInterval = DateInterval(start: startDate, end: now)
		case 2:
			let startDate = calendar.date(byAdding: .month, value: -1, to: now)!
			period = .month
			chartInterval = DateInterval(start: startDate, end: now)
		case 3:
			let startDate = calendar.date(byAdding: .year, value: -1, to: now)!
			period = .month
			chartInterval = DateInterval(start: startDate, end: now)
		default:
			let startDate = calendar.date(byAdding: .weekday, value: -7, to: now)!
			period = .week
			chartInterval = DateInterval(start: startDate, end: now)
		}
	}

	private func computeTaskIDOrder(taskIDs: [String]) -> [String: Int] {
		let sortedTaskIDs = taskIDs.enumerated().reduce(into: [String: Int]()) { taskDictionary, task in
			taskDictionary[task.element] = task.offset
		}
		return sortedTaskIDs
	}

	static func query() -> OCKEventQuery {
		let query = OCKEventQuery(dateInterval: .init())
		return query
	}
}

#Preview {
    InsightsView()
		.environment(\.careStore, Utility.createPreviewStore())
		.careKitStyle(Styler())
}
