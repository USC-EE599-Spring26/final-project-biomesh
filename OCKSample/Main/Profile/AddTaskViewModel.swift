//
//  AddTaskViewModel.swift
//  OCKSample
//
//  Created by Faye.
//

import Foundation
import CareKitStore
import HealthKit
import os.log
import UIKit

@MainActor
final class AddTaskViewModel: ObservableObject {

    enum TaskKind: String, CaseIterable, Identifiable {
        case regular   = "Regular Task"
        case healthKit = "HealthKit Task"
        var id: String { rawValue }
    }

    enum CardType: String, CaseIterable, Identifiable {
        case button          = "Button Log"
        case checklist       = "Checklist"
        case instructions    = "Instructions"
        case simple          = "Simple"
        case numericProgress = "Numeric Progress"
        case labeledValue    = "Labeled Value"
        case grid            = "Grid"
        case link            = "Link"
        case featuredContent = "Featured Content"
        var id: String { rawValue }

        var careKitCard: CareKitCard {
            switch self {
            case .button:          return .button
            case .checklist:       return .checklist
            case .instructions:    return .instruction
            case .simple:          return .simple
            case .numericProgress: return .numericProgress
            case .labeledValue:    return .labeledValue
            case .grid:            return .grid
            case .link:            return .link
            case .featuredContent: return .featured
            }
        }

        /// Optional metadata only — not used for rendering.
        var tagValue: String {
            switch self {
            case .button:          return "buttonLog"
            case .checklist:       return "checklist"
            case .instructions:    return "instructions"
            case .simple:          return "simple"
            case .numericProgress: return "numericProgress"
            case .labeledValue:    return "labeledValue"
            case .grid:            return "grid"
            case .link:            return "linkView"
            case .featuredContent: return "featuredContent"
            }
        }
    }

    enum Frequency: String, CaseIterable, Identifiable {
        case daily  = "Daily"
        case weekly = "Weekly"
        var id: String { rawValue }

        var interval: DateComponents {
            switch self {
            case .daily:  return DateComponents(day: 1)
            case .weekly: return DateComponents(weekOfYear: 1)
            }
        }
    }

    enum HealthKitMetric: String, CaseIterable, Identifiable {
        case steps      = "Steps"
        case heartRate  = "Heart Rate"
        var id: String { rawValue }
    }

    @Published var taskKind: TaskKind = .regular
    @Published var title: String = ""
    @Published var instructions: String = ""
    @Published var startDate: Date = .now
    @Published var timeOfDay: Date = .now
    @Published var frequency: Frequency = .daily
    @Published var cardType: CardType = .button
    @Published var assetName: String = ""

    @Published var healthKitMetric: HealthKitMetric = .steps
    @Published var stepsGoal: Double = 8000

    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    static let suggestedSymbols: [String] = [
        "cup.and.saucer.fill",
        "drop.fill",
        "brain.head.profile",
        "moon.zzz.fill",
        "figure.walk",
        "figure.run",
        "heart.fill",
        "bed.double.fill",
        "bolt.fill",
        "flame.fill",
        "cross.case.fill",
        "pills.fill",
        "waveform.path.ecg",
        "chart.line.uptrend.xyaxis",
        "alarm.fill",
        "sun.max.fill",
        "leaf.fill",
        "fork.knife",
        "music.note",
        "book.fill"
    ]

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && isValidSymbol
    }

    var isValidSymbol: Bool {
        let trimmed = assetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return UIImage(systemName: trimmed) != nil
    }

    func save() async -> Bool {
        guard canSave else { return false }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            switch taskKind {
            case .regular:
                let task = buildRegularTask()
                guard let store = AppDelegateKey.defaultValue?.store else {
                    throw AppError.couldntBeUnwrapped
                }
                _ = try await store.addTask(task)

            case .healthKit:
                let task = try buildHealthKitTask()
                guard let hkStore = AppDelegateKey.defaultValue?.healthKitStore else {
                    throw AppError.couldntBeUnwrapped
                }
                _ = try await hkStore.addTask(task)
                Utility.requestHealthKitPermissions()
            }

            NotificationCenter.default.post(
                name: Notification.Name(rawValue: Constants.shouldRefreshView),
                object: nil
            )
            Logger.profile.info("Saved new task: \(self.title, privacy: .private)")
            return true
        } catch {
            errorMessage = error.localizedDescription
            Logger.profile.error("Could not save task: \(error, privacy: .public)")
            return false
        }
    }

    private func buildSchedule() -> OCKSchedule {
        let hour = Calendar.current.component(.hour, from: timeOfDay)
        let minute = Calendar.current.component(.minute, from: timeOfDay)
        let start = Calendar.current.date(
            bySettingHour: hour, minute: minute, second: 0, of: startDate
        ) ?? startDate

        let element = OCKScheduleElement(
            start: start,
            end: nil,
            interval: frequency.interval,
            text: nil,
            targetValues: [],
            duration: .allDay
        )
        return OCKSchedule(composing: [element])
    }

    private func buildRegularTask() -> OCKTask {
        let id = "user.\(slug(title)).\(UUID().uuidString.prefix(6))"
        var task = OCKTask(
            id: id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            carePlanUUID: nil,
            schedule: buildSchedule()
        )

        task.instructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines)

        // This is what CareViewController uses to decide how to render the task.
        task.card = cardType.careKitCard

        // Optional metadata only.
        task.tags = ["cardType:\(cardType.tagValue)"]

        applyAsset(to: &task)
        return task
    }

    private func buildHealthKitTask() throws -> OCKHealthKitTask {
        let id = "user.hk.\(slug(title)).\(UUID().uuidString.prefix(6))"
        let schedule = buildSchedule()

        switch healthKitMetric {
        case .steps:
            let unit = HKUnit.count()
            let goalValue = OCKOutcomeValue(stepsGoal, units: unit.unitString)
            let scheduleWithGoal = OCKSchedule(composing: schedule.elements.map {
                OCKScheduleElement(
                    start: $0.start,
                    end: $0.end,
                    interval: $0.interval,
                    text: $0.text,
                    targetValues: [goalValue],
                    duration: $0.duration
                )
            })

            var task = OCKHealthKitTask(
                id: id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                carePlanUUID: nil,
                schedule: scheduleWithGoal,
                healthKitLinkage: OCKHealthKitLinkage(
                    quantityIdentifier: .stepCount,
                    quantityType: .cumulative,
                    unit: unit
                )
            )

            task.instructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines)

            // This is what CareViewController expects.
            task.card = .numericProgress

            // Optional metadata only.
            task.tags = ["cardType:numericProgress"]

            applyAsset(to: &task)
            return task

        case .heartRate:
            let unit = HKUnit.count().unitDivided(by: .minute())

            var task = OCKHealthKitTask(
                id: id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                carePlanUUID: nil,
                schedule: schedule,
                healthKitLinkage: OCKHealthKitLinkage(
                    quantityIdentifier: .heartRate,
                    quantityType: .discrete,
                    unit: unit
                )
            )

            task.instructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines)

            // This is what CareViewController expects.
            task.card = .labeledValue

            // Optional metadata only.
            task.tags = ["cardType:labeledValue"]

            applyAsset(to: &task)
            return task
        }
    }

    private func applyAsset(to task: inout OCKTask) {
        let trimmed = assetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        task.asset = trimmed
    }

    private func applyAsset(to task: inout OCKHealthKitTask) {
        let trimmed = assetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        task.asset = trimmed
    }

    private func slug(_ sss: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        let cleaned = sss.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .components(separatedBy: allowed.inverted)
            .joined()
        return cleaned.isEmpty ? "task" : cleaned
    }
}
