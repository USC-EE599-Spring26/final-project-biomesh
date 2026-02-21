//
//  AddTaskViewModel.swift
//  OCKSample
//
//  Created by Alarik Damrow on 2/20/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore

@MainActor
final class AddTaskViewModel: ObservableObject {

    @Published var title: String = "Hydration Check"
    @Published var instructions: String = "Drink water regularly today."
    @Published var startDate: Date = Date()

    enum Frequency: String, CaseIterable, Identifiable {
        case daily, weekly
        var id: String { rawValue }

        var interval: DateComponents {
            switch self {
            case .daily: return DateComponents(day: 1)
            case .weekly: return DateComponents(weekOfYear: 1)
            }
        }
    }

    enum CardType: String, CaseIterable, Identifiable {
        case simple
        case checklist
        case instructions
        case numericProgress
        case buttonLog
        case labeledValue
        case grid
        case link
        case featuredContent

        var id: String { rawValue }
    }

    @Published var frequency: Frequency = .daily
    @Published var cardType: CardType = .simple

    @Published var isSaving = false
    @Published var errorMessage: String?

    private let taskStore: any OCKAnyTaskStore

    init(taskStore: any OCKAnyTaskStore) {
        self.taskStore = taskStore
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() async -> Bool {
        guard canSave else { return false }

        isSaving = true
        defer { isSaving = false }

        let element = OCKScheduleElement(start: startDate, end: nil, interval: frequency.interval)
        let schedule = OCKSchedule(composing: [element])

        var task = OCKTask(
            id: "userTask.\(UUID().uuidString)",
            title: title,
            carePlanUUID: nil,
            schedule: schedule
        )

        task.instructions = instructions
        task.tags = [
            "cardType:\(cardType.rawValue)"
        ]

        do {
            _ = try await taskStore.addAnyTasks([task])
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
}
