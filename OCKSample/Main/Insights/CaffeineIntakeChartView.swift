//
//  CaffeineIntakeChartView.swift
//  OCKSample
//
//  Created by Faye.
//

import CareKitStore
import Charts
import SwiftUI

struct CaffeineIntakeChartView: View {
    let events: [OCKAnyEvent]
    let dateInterval: DateInterval
    let subtitle: String

    private struct DailyTotal: Identifiable {
        let id = UUID()
        let date: Date
        let totalMg: Double
    }

    private var caffeineEvents: [OCKAnyEvent] {
        events.filter {
            $0.task.id == TaskID.caffeineIntake
                && dateInterval.contains($0.scheduleEvent.start)
        }
        .sorted { $0.scheduleEvent.start < $1.scheduleEvent.start }
    }

    private var chartData: [DailyTotal] {
        caffeineEvents.compactMap { event in
            let values = event.outcome?.values ?? []
            guard !values.isEmpty else { return nil }
            let total = values.compactMap(\.doubleValue).reduce(0, +)
            return DailyTotal(date: event.scheduleEvent.start, totalMg: total)
        }
    }

    private var averageMg: Double {
        guard !chartData.isEmpty else { return 0 }
        return chartData.map(\.totalMg).reduce(0, +) / Double(chartData.count)
    }

    private var maxMg: Double {
        max(chartData.map(\.totalMg).max() ?? 0, 500)
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
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundStyle(.brown)
                    Text("Daily Caffeine")
                        .font(.title3.weight(.semibold))
                }

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if chartData.isEmpty {
                    Text("No caffeine data yet — log your drinks to see trends.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Average: \(Int(averageMg)) mg/day")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if !chartData.isEmpty {
                Chart {
                    ForEach(chartData) { item in
                        BarMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Caffeine (mg)", item.totalMg)
                        )
                        .foregroundStyle(
                            item.totalMg > 400
                                ? Color.red.gradient
                                : Color.brown.gradient
                        )
                        .cornerRadius(4)
                    }

                    RuleMark(y: .value("Limit", 400))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
                        .foregroundStyle(.red.opacity(0.7))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("400 mg limit")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.red)
                        }
                }
                .frame(height: 220)
                .chartYScale(domain: 0...maxMg)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }

                HStack(spacing: 16) {
                    Label("Under 400 mg", systemImage: "circle.fill")
                        .foregroundStyle(.brown)
                    Label("Over 400 mg", systemImage: "circle.fill")
                        .foregroundStyle(.red)
                }
                .font(.caption2)
            }
        }
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
