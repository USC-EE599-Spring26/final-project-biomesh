//
//  ManageTasksView.swift
//  OCKSample
//
//  Created by Alarik Damrow on 2/21/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
import CareKitStore
struct ManageTasksView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ManageTasksViewModel
    init(taskStore: any OCKAnyTaskStore) {
        _viewModel = StateObject(wrappedValue: ManageTasksViewModel(taskStore: taskStore))
    }
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading tasks…")
                } else {
                    List {
                        ForEach(viewModel.tasks.indices, id: \.self) { idx in
                            let t = viewModel.tasks[idx]
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.displayTitle(for: t))
                                        .font(.headline)

                                    Text(t.id)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                        }
                        .onDelete { offsets in
                            Task { await viewModel.delete(at: offsets) }
                        }
                    }
                }
            }
            .navigationTitle("Manage Tasks")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await viewModel.load()
            }
            .alert("Couldn’t delete task", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }
}
@MainActor
final class ManageTasksViewModel: ObservableObject {
    @Published var tasks: [any OCKAnyTask] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?

    private let taskStore: any OCKAnyTaskStore

    init(taskStore: any OCKAnyTaskStore) {
        self.taskStore = taskStore
    }
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            var q = OCKTaskQuery(for: Date())
            // IMPORTANT: show tasks even if they have no events (so user can delete anything)
            q.excludesTasksWithNoEvents = false

            let fetched = try await taskStore.fetchAnyTasks(query: q)
            // Sort nicely
            tasks = fetched.sorted {
                displayTitle(for: $0).localizedCaseInsensitiveCompare(displayTitle(for: $1)) == .orderedAscending
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func delete(at offsets: IndexSet) async {
        let toDelete = offsets.map { tasks[$0] }

        do {
            _ = try await taskStore.deleteAnyTasks(toDelete)
            tasks.remove(atOffsets: offsets)
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: Constants.shouldRefreshView),
                object: nil
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func displayTitle(for task: any OCKAnyTask) -> String {
        if let t = task as? OCKTask { return t.title ?? t.id }
        if let hk = task as? OCKHealthKitTask { return hk.title ?? hk.id }
        return task.id
    }
}
