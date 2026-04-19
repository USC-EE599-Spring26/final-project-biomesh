//
//  WindDownChartCardView.swift
//  OCKSample
//
//  Created by Alarik Damrow on 4/19/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import Charts
import SwiftUI

struct WindDownChartCardView: View {
    let events: [OCKAnyEvent]
    let subtitle: String

    private struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let completedHabits: Int
    }

    private var windDownEvents: [OCKAnyEvent] {
        let filtered = events.filter { event in
            event.task.id == TaskID.sleepHygiene
        }

        return filtered.sorted { left, right in
            left.scheduleEvent.start < right.scheduleEvent.start
        }
    }

    private var chartData: [DataPoint] {
        windDownEvents.compactMap { event in
            guard let values = event.outcome?.values, !values.isEmpty else {
                return nil
            }

            return DataPoint(
                date: event.scheduleEvent.start,
                completedHabits: values.count
            )
        }
    }

    private var averageScore: Double {
        guard !chartData.isEmpty else { return 0 }
        let total = chartData.reduce(0) { partial, item in
            partial + item.completedHabits
        }
        return Double(total) / Double(chartData.count)
    }

    private var backgroundColor: Color {
        #if os(watchOS)
        return Color.gray.opacity(0.2)
        #else
        return Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Evening Wind-Down")
                    .font(.title3.weight(.semibold))

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if chartData.isEmpty {
                    Text("No data yet — complete your wind-down routine to see insights.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Average completion: \(averageScore, specifier: "%.1f") / 3 habits")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if !chartData.isEmpty {
                Chart(chartData) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Completed Habits", item.completedHabits)
                    )

                    RuleMark(y: .value("Goal", 3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(.secondary)
                }
                .frame(height: 220)
                .chartYScale(domain: 0...3)
                .chartYAxis {
                    AxisMarks(values: [0, 1, 2, 3])
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Label("0 = none completed", systemImage: "circle")
                    Label("3 = full wind-down routine completed", systemImage: "checkmark.circle.fill")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
