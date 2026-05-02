//
//  WeeklySummaryCardView.swift
//  OCKSample
//
//  Created by Faye.
//

import CareKitStore
import SwiftUI

struct WeeklySummaryCardView: View {
    let events: [OCKAnyEvent]
    let dateInterval: DateInterval

    private var filteredEvents: [OCKAnyEvent] {
        events.filter { dateInterval.contains($0.scheduleEvent.start) }
    }

    private var caffeineEvents: [OCKAnyEvent] {
        filteredEvents.filter { $0.task.id == TaskID.caffeineIntake }
    }

    private var anxietyEvents: [OCKAnyEvent] {
        filteredEvents.filter { $0.task.id == TaskID.anxietyCheck }
    }

    private var windDownEvents: [OCKAnyEvent] {
        filteredEvents.filter { $0.task.id == TaskID.sleepHygiene }
    }

    private var waterEvents: [OCKAnyEvent] {
        filteredEvents.filter { $0.task.id == TaskID.waterIntake }
    }

    private var dayCount: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: dateInterval.start,
            to: dateInterval.end
        ).day ?? 1
        return max(days, 1)
    }

    private var totalCaffeineMg: Int {
        let total = caffeineEvents
            .compactMap(\.outcome)
            .flatMap(\.values)
            .compactMap(\.doubleValue)
            .reduce(0, +)
        return Int(total)
    }

    private var avgDailyCaffeineMg: Int {
        totalCaffeineMg / dayCount
    }

    private var anxietyCount: Int {
        anxietyEvents
            .compactMap(\.outcome)
            .flatMap(\.values)
            .count
    }

    private var windDownRate: Int {
        let completed = windDownEvents.filter { ($0.outcome?.values.count ?? 0) > 0 }.count
        let total = windDownEvents.count
        guard total > 0 else { return 0 }
        return Int(Double(completed) / Double(total) * 100)
    }

    private var totalWaterOz: Int {
        let total = waterEvents
            .compactMap(\.outcome)
            .flatMap(\.values)
            .compactMap(\.doubleValue)
            .reduce(0, +)
        return Int(total)
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
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundStyle(.blue)
                Text("BioMesh Summary")
                    .font(.title3.weight(.semibold))
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                statCard(
                    value: "\(totalCaffeineMg)",
                    unit: "mg",
                    label: "Caffeine",
                    icon: "cup.and.saucer.fill",
                    color: .brown,
                    warning: avgDailyCaffeineMg > 400
                )

                statCard(
                    value: "\(anxietyCount)",
                    unit: anxietyCount == 1 ? "episode" : "episodes",
                    label: "Anxiety",
                    icon: "brain.head.profile",
                    color: .purple,
                    warning: anxietyCount > 3
                )

                statCard(
                    value: "\(windDownRate)",
                    unit: "%",
                    label: "Wind-Down",
                    icon: "moon.zzz.fill",
                    color: .indigo,
                    warning: false
                )

                statCard(
                    value: "\(totalWaterOz)",
                    unit: "fl oz",
                    label: "Water",
                    icon: "drop.fill",
                    color: .cyan,
                    warning: false
                )
            }

            if avgDailyCaffeineMg > 400 {
                Label(
                    "Daily caffeine avg exceeds 400 mg — linked to higher anxiety risk",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(.red)
            }
        }
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func statCard(
        value: String,
        unit: String,
        label: String,
        icon: String,
        color: Color,
        warning: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(warning ? .red : .primary)
                Text(unit)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
