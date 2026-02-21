//
//  CreateTaskViewModel.swift
//  OCKSample
//
//  Created by Alarik Damrow on 2/21/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import Foundation

@MainActor
final class CreateTaskViewModel: ObservableObject {

    // Required properties
    @Published var title: String = ""
    @Published var instructions: String = ""

    // Schedule (simple + meets requirement)
    @Published var startDate: Date = .now
    @Published var repeatRule: RepeatRule = .daily
    @Published var timeOfDay: Date = .now
    @Published var cardType: CardType = .instructions

    enum CardType: String, CaseIterable, Identifiable {
        case instructions
        case simple
        case checklist
        case buttonLog
        case numericProgress
        case labeledValue
        case link
        case featuredContent
        // (grid later if you add a GridTaskView SwiftUI type)

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
    

    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    private let store: OCKStore

    init(store: OCKStore) {
        self.store = store
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() async -> Bool {
        guard canSave else { return false }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let task = buildTask()
            _ = try await store.addTask(task)

            // This triggers your CareViewController observer -> reload()
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

    private func buildTask() -> OCKTask {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedInstructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines)

        // Create a unique ID so it can't collide with sample tasks
        let id = "user.\(slug(trimmedTitle)).\(UUID().uuidString.prefix(6))"

        let schedule = buildSchedule()

        var task = OCKTask(
            id: id,
            title: trimmedTitle,
            carePlanUUID: nil,
            schedule: schedule
        )

        // Store the user-editable fields
        task.instructions = trimmedInstructions

        // Your CareViewController default path looks for tags "cardType:*"
        // We'll default to Instructions card so instructions are visible.
        task.tags = ["cardType:\(cardType.rawValue)"]

        return task
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
