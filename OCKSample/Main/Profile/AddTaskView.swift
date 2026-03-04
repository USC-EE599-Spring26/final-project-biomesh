//
//  AddTaskView.swift
//  OCKSample
//
//  Created by Faye.
//

import SwiftUI
import CareKitStore

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddTaskViewModel()

    var body: some View {
        NavigationView {
            Form {

                // Task kind picker
                Section(header: Text("Task Type")) {
                    Picker("Type", selection: $viewModel.taskKind) {
                        ForEach(AddTaskViewModel.TaskKind.allCases) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Basic info
                Section(header: Text("Details")) {
                    TextField("Title", text: $viewModel.title)

                    TextField(
                        "Instructions",
                        text: $viewModel.instructions,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }

                // Schedule
                Section(header: Text("Schedule")) {
                    DatePicker(
                        "Start Date",
                        selection: $viewModel.startDate,
                        displayedComponents: .date
                    )
                    DatePicker(
                        "Time",
                        selection: $viewModel.timeOfDay,
                        displayedComponents: .hourAndMinute
                    )
                    Picker("Repeats", selection: $viewModel.frequency) {
                        ForEach(AddTaskViewModel.Frequency.allCases) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                }

                // HealthKit-specific options
                if viewModel.taskKind == .healthKit {
                    Section(header: Text("HealthKit Metric")) {
                        Picker("Metric", selection: $viewModel.healthKitMetric) {
                            ForEach(AddTaskViewModel.HealthKitMetric.allCases) { mmm in
                                Text(mmm.rawValue).tag(mmm)
                            }
                        }
                        if viewModel.healthKitMetric == .steps {
                            Stepper(
                                "Daily Goal: \(Int(viewModel.stepsGoal)) steps",
                                value: $viewModel.stepsGoal,
                                in: 500...30000,
                                step: 500
                            )
                        }
                    }
                }

                // Card type
                if viewModel.taskKind == .regular {
                    Section(header: Text("Card Style")) {
                        Picker("Style", selection: $viewModel.cardType) {
                            ForEach(AddTaskViewModel.CardType.allCases) { card in
                                Text(card.rawValue).tag(card)
                            }
                        }
                    }
                }

                // SF Symbol asset
                Section(header: Text("Icon (SF Symbol — optional)")) {
                    TextField(
                        "e.g. cup.and.saucer.fill",
                        text: $viewModel.assetName
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)

                    // Live preview + validation
                    HStack(spacing: 10) {
                        let trimmed = viewModel.assetName
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            Image(systemName: "square.grid.2x2")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("Pick from below or type a name")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        } else if viewModel.isValidSymbol {
                            Image(systemName: trimmed)
                                .font(.title2)
                                .foregroundColor(.accentColor)
                            Text("Looks good!")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                            Text("Not a valid SF Symbol name")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }

                    // Quick-select grid
                    Text("Quick Select")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(AddTaskViewModel.suggestedSymbols, id: \.self) { sym in
                                Button {
                                    viewModel.assetName = sym
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: sym)
                                            .font(.title3)
                                        Text(sym)
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .frame(maxWidth: 80)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                viewModel.assetName == sym
                                                ? Color.accentColor
                                                : Color.gray.opacity(0.25),
                                                lineWidth: 1.5
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Error display
                if let msg = viewModel.errorMessage {
                    Section {
                        Text(msg)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            let saved = await viewModel.save()
                            if saved { dismiss() }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .bold()
                        }
                    }
                    .disabled(!viewModel.canSave || viewModel.isSaving)
                }
            }
        }
    }
}

#Preview {
    AddTaskView()
        .environment(\.careStore, Utility.createPreviewStore())
}
