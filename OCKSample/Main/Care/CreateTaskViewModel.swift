//
//  CreateTaskViewModel.swift
//  OCKSample
//
//  Created by Alarik Damrow on 2/21/26.
//  Updated by You
//

import CareKitStore
import Foundation
import HealthKit
#if canImport(UIKit)
import UIKit
#endif
@MainActor
final class CreateTaskViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var instructions: String = ""
    @Published var startDate: Date = .now
    @Published var repeatRule: RepeatRule = .daily
    @Published var timeOfDay: Date = .now
    @Published var cardType: CardType = .instructions
    @Published var assetName: String = ""
    enum TaskKind: String, CaseIterable, Identifiable {
        case regular
        case healthKit
        var id: String { rawValue }
        var label: String {
            switch self {
            case .regular: return "Regular"
            case .healthKit: return "HealthKit"
            }
        }
    }
    @Published var taskKind: TaskKind = .regular
    enum HealthKitMetric: String, CaseIterable, Identifiable {
        case steps
        var id: String { rawValue }
        var label: String {
            switch self {
            case .steps: return "Steps"
            }
        }
    }
    @Published var healthKitMetric: HealthKitMetric = .steps
    @Published var stepsGoal: Double = 2000
    static let generalSymbols: [String] = [
        "star",
        "heart",
        "checkmark.circle.fill",
        "flag.fill",
        "drop.fill",
        "cup.and.saucer.fill",
        "leaf.fill",
        "fork.knife",
        "figure.walk",
        "figure.run",
        "bed.double.fill",
        "moon.fill",
        "sun.max.fill",
        "brain.head.profile",
        "book.fill",
        "pills.fill",
        "cross.case.fill",
        "timer",
        "alarm.fill",
        "calendar",
        "bolt.fill",
        "flame.fill",
        "cart.fill",
        "music.note",
        "headphones",
        "phone.fill",
        "person.fill"
    ]
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?
    enum CardType: String, CaseIterable, Identifiable {
        case instructions
        case simple
        case checklist
        case buttonLog
        case numericProgress
        case labeledValue
        case link
        case featuredContent
        var id: String { rawValue }
        var label: String {
            switch self {
            case .instructions: return "Instructions"
            case .simple: return "Simple"
            case .checklist: return "Checklist"
            case .buttonLog: return "Button Log"
            case .numericProgress: return "Numeric Progress"
            case .labeledValue: return "Labeled Value"
            case .link: return "Link"
            case .featuredContent: return "Featured Content"
            }
        }
    }
    enum RepeatRule: String, CaseIterable, Identifiable {
        case daily = "Daily"
        case weekly = "Weekly"
        var id: String { rawValue }
    }
    private let store: OCKStore
    private let healthKitStore: OCKHealthKitPassthroughStore?
    init(store: OCKStore, healthKitStore: OCKHealthKitPassthroughStore?) {
        self.store = store
        self.healthKitStore = healthKitStore
    }
    var healthKitAvailable: Bool { healthKitStore != nil }
    var isValidSFSymbol: Bool {
        let trimmed = assetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        #if canImport(UIKit)
        return UIImage(systemName: trimmed) != nil
        #else
        return true
        #endif
    }
    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && (taskKind == .regular || healthKitAvailable)
        && isValidSFSymbol
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
                _ = try await store.addTask(task)
            case .healthKit:
                guard let hkStore = healthKitStore else {
                    throw NSError(
                        domain: "HealthKit",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "HealthKit store not available"]
                    )
                }
                let task = try buildHealthKitTask()
                _ = try await hkStore.addTask(task)
            }
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: Constants.shouldRefreshView),
                object: nil
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    private func buildRegularTask() -> OCKTask {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedInstructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines)

        let id = "user.\(slug(trimmedTitle)).\(UUID().uuidString.prefix(6))"
        let schedule = buildSchedule()

        var task = OCKTask(
            id: id,
            title: trimmedTitle,
            carePlanUUID: nil,
            schedule: schedule
        )
        task.instructions = trimmedInstructions
        task.tags = ["cardType:\(cardType.rawValue)"]
        applyAssetIfNeeded(to: &task)
        return task
    }
    private func buildHealthKitTask() throws -> OCKHealthKitTask {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedInstructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = "user.hk.\(slug(trimmedTitle)).\(UUID().uuidString.prefix(6))"
        let schedule = buildSchedule()

        switch healthKitMetric {
        case .steps:
            let unit = HKUnit.count()
            let goalValue = OCKOutcomeValue(stepsGoal, units: unit.unitString)
            let scheduleWithGoal = OCKSchedule(
                composing: schedule.elements.map { element in
                    OCKScheduleElement(
                        start: element.start,
                        end: element.end,
                        interval: element.interval,
                        text: element.text,
                        targetValues: [goalValue],
                        duration: element.duration
                    )
                }
            )
            var task = OCKHealthKitTask(
                id: id,
                title: trimmedTitle.isEmpty ? "Steps" : trimmedTitle,
                carePlanUUID: nil,
                schedule: scheduleWithGoal,
                healthKitLinkage: OCKHealthKitLinkage(
                    quantityIdentifier: .stepCount,
                    quantityType: .cumulative,
                    unit: unit
                )
            )
            task.instructions = trimmedInstructions.isEmpty
            ? "Tracks your steps from HealthKit."
            : trimmedInstructions
            task.tags = ["cardType:numericProgress"]
            if assetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                task.asset = "figure.walk"
            } else {
                applyAssetIfNeeded(to: &task)
            }
            return task
        }
    }
    private func applyAssetIfNeeded(to task: inout OCKTask) {
        let trimmed = assetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        task.asset = trimmed
    }
    private func applyAssetIfNeeded(to task: inout OCKHealthKitTask) {
        let trimmed = assetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        task.asset = trimmed
    }
    private func buildSchedule() -> OCKSchedule {
        let hour = Calendar.current.component(.hour, from: timeOfDay)
        let minute = Calendar.current.component(.minute, from: timeOfDay)
        let start = Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: startDate
        ) ?? startDate
        let interval: DateComponents
        switch repeatRule {
        case .daily:
            interval = DateComponents(day: 1)
        case .weekly:
            interval = DateComponents(weekOfYear: 1)
        }
        let element = OCKScheduleElement(
            start: start,
            end: nil,
            interval: interval,
            text: nil,
            targetValues: [],
            duration: .allDay
        )
        return OCKSchedule(composing: [element])
    }
    private func slug(_ s: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        let cleaned = s.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .components(separatedBy: allowed.inverted)
            .joined()
        return cleaned.isEmpty ? "task" : cleaned
    }
}
