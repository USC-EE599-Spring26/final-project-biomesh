//
//  CaffeineAnxietyChartView.swift
//  OCKSample
//
//  Created by Faye.
//

import CareKitStore
import Charts
import SwiftUI

struct CaffeineAnxietyChartView: View {
    let events: [OCKAnyEvent]
    let dateInterval: DateInterval
    let subtitle: String

    private struct DayData: Identifiable {
        let id = UUID()
        let date: Date
        let caffeinePercent: Double
        let anxietyPercent: Double
    }

    private var filteredEvents: [OCKAnyEvent] {
        events.filter { dateInterval.contains($0.scheduleEvent.start) }
    }

    private var chartData: [DayData] {
        let calendar = Calendar.current

        let caffeineByDay = Dictionary(grouping: filteredEvents.filter {
            $0.task.id == TaskID.caffeineIntake
        }) { event in
            calendar.startOfDay(for: event.scheduleEvent.start)
        }

        let anxietyByDay = Dictionary(grouping: filteredEvents.filter {
            $0.task.id == TaskID.anxietyCheck
        }) { event in
            calendar.startOfDay(for: event.scheduleEvent.start)
        }

        let allDates = Set(caffeineByDay.keys).union(anxietyByDay.keys).sorted()

        let rawCaffeine: [Date: Double] = allDates.reduce(into: [:]) { dict, date in
            dict[date] = caffeineByDay[date]?
                .compactMap(\.outcome)
                .flatMap(\.values)
                .compactMap(\.doubleValue)
                .reduce(0, +) ?? 0
        }

        let rawAnxiety: [Date: Double] = allDates.reduce(into: [:]) { dict, date in
            dict[date] = Double(
                anxietyByDay[date]?
                    .compactMap(\.outcome)
                    .flatMap(\.values)
                    .count ?? 0
            )
        }

        let maxCaffeine = rawCaffeine.values.max() ?? 1
        let maxAnxiety = rawAnxiety.values.max() ?? 1

        return allDates.compactMap { date in
            let caf = rawCaffeine[date] ?? 0
            let anx = rawAnxiety[date] ?? 0
            guard caf > 0 || anx > 0 else { return nil }

            return DayData(
                date: date,
                caffeinePercent: maxCaffeine > 0 ? (caf / maxCaffeine) * 100 : 0,
                anxietyPercent: maxAnxiety > 0 ? (anx / maxAnxiety) * 100 : 0
            )
        }
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
                    Image(systemName: "arrow.triangle.swap")
                        .foregroundStyle(.purple)
                    Text("Caffeine vs Anxiety")
                        .font(.title3.weight(.semibold))
                }

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if chartData.isEmpty {
                    Text("Log caffeine and anxiety to see their correlation over time.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if chartData.count == 1 {
                    Text("Log more days to see correlation trends.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Both metrics normalized to their peak value (100%)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if !chartData.isEmpty {
                Chart {
                    ForEach(chartData) { item in
                        BarMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Caffeine %", item.caffeinePercent)
                        )
                        .foregroundStyle(Color.brown.opacity(0.6))
                        .position(by: .value("Type", "Caffeine"))
                    }

                    ForEach(chartData) { item in
                        LineMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Anxiety %", item.anxietyPercent)
                        )
                        .foregroundStyle(.purple)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Anxiety %", item.anxietyPercent)
                        )
                        .foregroundStyle(.purple)
                        .symbolSize(40)
                    }
                }
                .frame(height: 220)
                .chartYScale(domain: 0...100)
                .chartYAxisLabel("% of peak")
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }

                HStack(spacing: 16) {
                    Label("Caffeine", systemImage: "square.fill")
                        .foregroundStyle(.brown)
                    Label("Anxiety", systemImage: "line.diagonal")
                        .foregroundStyle(.purple)
                }
                .font(.caption2)
            }
        }
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
