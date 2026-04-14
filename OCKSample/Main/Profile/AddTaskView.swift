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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    topBar

                    Text("Add Task")
                        .font(.system(size: 34, weight: .bold))
                        .padding(.horizontal, 20)

                    addSection(title: "Task Type") {
                        Picker("Type", selection: $viewModel.taskKind) {
                            ForEach(AddTaskViewModel.TaskKind.allCases) { kind in
                                Text(kind.rawValue).tag(kind)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    addSection(title: "Details") {
                        TextField("Title", text: $viewModel.title)
                            .padding(.vertical, 12)
                        Divider()
                        TextField(
                            "Instructions",
                            text: $viewModel.instructions,
                            axis: .vertical
                        )
                        .lineLimit(3...6)
                        .padding(.vertical, 12)
                    }

                    addSection(title: "Schedule") {
                        DatePicker(
                            "Start Date",
                            selection: $viewModel.startDate,
                            displayedComponents: .date
                        )
                        .padding(.vertical, 10)
                        Divider()
                        DatePicker(
                            "Time",
                            selection: $viewModel.timeOfDay,
                            displayedComponents: .hourAndMinute
                        )
                        .padding(.vertical, 10)
                        Divider()
                        Picker("Repeats", selection: $viewModel.frequency) {
                            ForEach(AddTaskViewModel.Frequency.allCases) { freq in
                                Text(freq.rawValue).tag(freq)
                            }
                        }
                        .padding(.vertical, 10)
                    }

                    if viewModel.taskKind == .healthKit {
                        addSection(title: "HealthKit Metric") {
                            Picker("Metric", selection: $viewModel.healthKitMetric) {
                                ForEach(AddTaskViewModel.HealthKitMetric.allCases) { metric in
                                    Text(metric.rawValue).tag(metric)
                                }
                            }
                            .padding(.vertical, 10)
                            if viewModel.healthKitMetric == .steps {
                                Divider()
                                Stepper(
                                    "Daily Goal: \(Int(viewModel.stepsGoal)) steps",
                                    value: $viewModel.stepsGoal,
                                    in: 500...30000,
                                    step: 500
                                )
                                .padding(.vertical, 10)
                            }
                        }
                    }

                    if viewModel.taskKind == .regular {
                        addSection(title: "Card Style") {
                            Picker("Style", selection: $viewModel.cardType) {
                                ForEach(AddTaskViewModel.CardType.allCases) { card in
                                    Text(card.rawValue).tag(card)
                                }
                            }
                            .padding(.vertical, 10)
                        }
                    }

                    addSection(title: "Icon (SF Symbol — optional)") {
                        TextField(
                            "e.g. cup.and.saucer.fill",
                            text: $viewModel.assetName
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(.vertical, 12)

                        Divider()

                        HStack(spacing: 10) {
                            let trimmed = viewModel.assetName
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            if trimmed.isEmpty {
                                Image(systemName: "square.grid.2x2")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("Pick from below or type a name")
                                    .foregroundColor(.secondary)
                            } else if viewModel.isValidSymbol {
                                Image(systemName: trimmed)
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                Text("Looks good!")
                                    .foregroundColor(.secondary)
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                Text("Not a valid SF Symbol name")
                                    .foregroundColor(.orange)
                            }
                        }
                        .font(.caption)
                        .padding(.vertical, 12)

                        Divider()

                        Text("Quick Select")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(AddTaskViewModel.suggestedSymbols, id: \.self) { sym in
                                    Button {
                                        viewModel.assetName = sym
                                    } label: {
                                        VStack(spacing: 8) {
                                            Image(systemName: sym)
                                                .font(.title2)
                                                .frame(height: 28)
                                            Text(sym)
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 96)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(
                                                    viewModel.assetName == sym
                                                    ? Color.accentColor
                                                    : Color.gray.opacity(0.18),
                                                    lineWidth: 1.5
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }

                    if let msg = viewModel.errorMessage {
                        Text(msg)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private var topBar: some View {
        HStack {
            pillButton(title: "Cancel") {
                dismiss()
            }

            Spacer()

            Button {
                Task {
                    let saved = await viewModel.save()
                    if saved { dismiss() }
                }
            } label: {
                Group {
                    if viewModel.isSaving {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(
                    viewModel.canSave && !viewModel.isSaving
                    ? Color.primary
                    : Color.secondary.opacity(0.7)
                )
                .frame(minWidth: 72)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.white)
                .clipShape(Capsule())
            }
            .disabled(!viewModel.canSave || viewModel.isSaving)
        }
        .padding(.horizontal, 20)
    }

    private func addSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)
            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .padding(.horizontal, 20)
    }

    private func pillButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(size: 18, weight: .medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.white)
            .clipShape(Capsule())
    }
}

#Preview {
    AddTaskView()
        .environment(\.careStore, Utility.createPreviewStore())
}
