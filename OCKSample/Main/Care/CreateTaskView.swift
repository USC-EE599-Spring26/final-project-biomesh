//
//  CreateTaskView.swift
//  OCKSample
//
//  Created by Alarik Damrow on 2/21/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
import CareKitStore
#if canImport(UIKit)
import UIKit
#endif
struct CreateTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateTaskViewModel
    init(store: OCKStore, healthKitStore: OCKHealthKitPassthroughStore?) {
        _viewModel = StateObject(
            wrappedValue: CreateTaskViewModel(store: store, healthKitStore: healthKitStore)
        )
    }
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $viewModel.title)

                    TextField("Instructions", text: $viewModel.instructions, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section(header: Text("Task Source")) {
                    Picker("Type", selection: $viewModel.taskKind) {
                        ForEach(CreateTaskViewModel.TaskKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    if viewModel.taskKind == .healthKit {
                        if viewModel.healthKitAvailable {
                            Picker("HealthKit Metric", selection: $viewModel.healthKitMetric) {
                                ForEach(CreateTaskViewModel.HealthKitMetric.allCases) { metric in
                                    Text(metric.label).tag(metric)
                                }
                            }
                            if viewModel.healthKitMetric == .steps {
                                Stepper(
                                    "Daily Goal: \(Int(viewModel.stepsGoal))",
                                    value: $viewModel.stepsGoal,
                                    in: 500...30000,
                                    step: 500
                                )
                            }
                        } else {
                            Text("HealthKit is not available in this build/run environment.")
                                .foregroundColor(.secondary)
                        }
                    }
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
                Section(header: Text("Icon (SF Symbol)")) {
                    TextField("Enter symbol name (e.g. drop.fill)", text: $viewModel.assetName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    #if canImport(UIKit)
                    HStack(spacing: 12) {
                        let trimmed = viewModel.assetName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty, UIImage(systemName: trimmed) != nil {
                            Image(systemName: trimmed)
                                .font(.title2)
                            Text("Preview")
                                .foregroundColor(.secondary)
                        } else if trimmed.isEmpty {
                            Image(systemName: "square.grid.2x2")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("Optional")
                                .foregroundColor(.secondary)
                        } else {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title2)
                                .foregroundColor(.orange)
                            Text("Not a valid SF Symbol")
                                .foregroundColor(.orange)
                        }
                    }
                    #endif
                    Divider()
                    Text("Quick Select")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(CreateTaskViewModel.generalSymbols, id: \.self) { symbol in
                                Button {
                                    viewModel.assetName = symbol
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: symbol)
                                            .font(.title3)

                                        Text(symbol)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .frame(maxWidth: 90)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                viewModel.assetName == symbol ? Color.accentColor : Color.gray.opacity(0.25),
                                                lineWidth: 1
                                            )
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                if viewModel.taskKind == .regular {
                    Section(header: Text("Card Type")) {
                        Picker("Style", selection: $viewModel.cardType) {
                            ForEach(CreateTaskViewModel.CardType.allCases) { type in
                                Text(type.label).tag(type)
                            }
                        }
                    }
                }
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error).foregroundColor(.red)
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
