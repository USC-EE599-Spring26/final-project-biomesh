//
//  CreateTaskView.swift
//  OCKSample
//
//  Created by Alarik Damrow on 2/21/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
import SwiftUI
import CareKitStore
struct CreateTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateTaskViewModel

    init(store: OCKStore) {
        _viewModel = StateObject(wrappedValue: CreateTaskViewModel(store: store))
    }
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $viewModel.title)

                    TextField("Instructions", text: $viewModel.instructions, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section(header: Text("Schedule")) {
                    DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: [.date])

                    Picker("Repeats", selection: $viewModel.repeatRule) {
                        ForEach(CreateTaskViewModel.RepeatRule.allCases) { rule in
                            Text(rule.rawValue).tag(rule)
                        }
                    }
                    DatePicker("Time", selection: $viewModel.timeOfDay, displayedComponents: [.hourAndMinute])
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error).foregroundColor(.red)
                    }
                }
                Section(header: Text("Card Type")) {
                    Picker("Style", selection: $viewModel.cardType) {
                        ForEach(CreateTaskViewModel.CardType.allCases) { type in
                            Text(type.label).tag(type)
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            let ok = await viewModel.save()
                            if ok { dismiss() }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(!viewModel.canSave || viewModel.isSaving)
                }
            }
        }
    }
}
