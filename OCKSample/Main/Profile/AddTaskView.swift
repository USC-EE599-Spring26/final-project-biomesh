//
//  AddTaskView.swift
//  OCKSample
//
//  Created by Alarik Damrow on 2/20/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
import SwiftUI
import CareKitStore
struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddTaskViewModel

    init(taskStore: any OCKAnyTaskStore) {
        _viewModel = StateObject(wrappedValue: AddTaskViewModel(taskStore: taskStore))
    }
    var body: some View {
        Form {
            Section("Task") {
                TextField("Title", text: $viewModel.title)
                TextEditor(text: $viewModel.instructions)
                    .frame(minHeight: 120)
            }
            Section("Card") {
                Picker("Card Type", selection: $viewModel.cardType) {
                    ForEach(AddTaskViewModel.CardType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }
            Section("Schedule") {
                DatePicker("Start Date",
                           selection: $viewModel.startDate,
                           displayedComponents: .date)

                Picker("Frequency", selection: $viewModel.frequency) {
                    ForEach(AddTaskViewModel.Frequency.allCases) { freq in
                        Text(freq.rawValue.capitalized).tag(freq)
                    }
                }
            }
            if let msg = viewModel.errorMessage {
                Section { Text(msg).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Add Task")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        let success = await viewModel.save()
                        if success { dismiss() }
                    }
                }
                .disabled(!viewModel.canSave || viewModel.isSaving)
            }
        }
    }
}
