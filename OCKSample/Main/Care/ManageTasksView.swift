//
//  ManageTasksView.swift
//  OCKSample
//
//  Created by Faye.
//

import SwiftUI
import CareKitStore
import os.log

// MARK: - View

struct ManageTasksView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ManageTasksViewModel()

    var body: some View {
        NavigationStack {
            content
                .task { await viewModel.load() }
                .alert("Could not delete task", isPresented: $viewModel.showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.errorMessage ?? "Unknown error")
                }
                .background(Color(.systemGroupedBackground))
                .safeAreaInset(edge: .top, spacing: 0) {
                    topBar
                        .padding(.top, 6)
                        .padding(.bottom, 10)
                        .background(.ultraThinMaterial)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading tasks…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.tasks.isEmpty {
            ContentUnavailableView(
                "No Tasks",
                systemImage: "tray",
                description: Text("Add a task from the Profile screen first.")
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Manage Tasks")
                        .font(.system(size: 34, weight: .bold))
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    taskList
                }
                .padding(.vertical, 12)
            }
        }
    }

    private var taskList: some View {
        LazyVStack(spacing: 14) {
            ForEach(viewModel.tasks.indices, id: \.self) { index in
                let task = viewModel.tasks[index]
                TaskRowView(
                    title: viewModel.displayTitle(for: task),
                    taskID: task.id,
                    assetName: task.asset,
                    onDelete: {
                        Task { await viewModel.delete(at: IndexSet(integer: index)) }
                    }
                )
            }
        }
        .padding(.horizontal, 20)
    }

    private var topBar: some View {
        HStack {
            Button("Done") { dismiss() }
                .font(.system(size: 18, weight: .medium))
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.white)
                .clipShape(Capsule())

            Spacer()

            Button {
                Task { await viewModel.load() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 22, weight: .medium))
                    .frame(width: 50, height: 50)
                    .background(.white)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
    }
}

private struct TaskRowView: View {
    let title: String
    let taskID: String
    let assetName: String?
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let symbolName = validatedSFSymbolName(assetName) {
                Image(systemName: symbolName)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 30)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)

                Text(taskID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.red)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func validatedSFSymbolName(_ name: String?) -> String? {
        guard let name, !name.isEmpty else { return nil }
        guard UIImage(systemName: name) != nil else { return nil }
        return name
    }
}

// MARK: - ViewModel

@MainActor
final class ManageTasksViewModel: ObservableObject {

    @Published var tasks: [any OCKAnyTask] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }

        guard let appDelegate = AppDelegateKey.defaultValue else {
            tasks = []
            return
        }

        do {
            var query = OCKTaskQuery(for: Date())
            query.excludesTasksWithNoEvents = false

            let regularTasks = try await appDelegate.store.fetchAnyTasks(query: query)
            let healthKitTasks = try await appDelegate.healthKitStore.fetchAnyTasks(query: query)

            tasks = sortTasks(regularTasks + healthKitTasks)
        } catch {
            present(error: error)
        }
    }

    func delete(at offsets: IndexSet) async {
        guard let appDelegate = AppDelegateKey.defaultValue else { return }

        let tasksToDelete = offsets.map { tasks[$0] }
        let regularTasks = tasksToDelete.compactMap { $0 as? OCKTask }
        let healthKitTasks = tasksToDelete.compactMap { $0 as? OCKHealthKitTask }

        do {
            if !regularTasks.isEmpty {
                _ = try await appDelegate.store.deleteTasks(regularTasks)
            }
            if !healthKitTasks.isEmpty {
                _ = try await appDelegate.healthKitStore.deleteTasks(healthKitTasks)
            }

            tasks.remove(atOffsets: offsets)

            NotificationCenter.default.post(
                name: Notification.Name(rawValue: Constants.shouldRefreshView),
                object: nil
            )

            Logger.profile.info("Deleted \(tasksToDelete.count) task(s)")
        } catch {
            present(error: error)
        }
    }

    func displayTitle(for task: any OCKAnyTask) -> String {
        if let regularTask = task as? OCKTask {
            return regularTask.title ?? regularTask.id
        }
        if let healthKitTask = task as? OCKHealthKitTask {
            return healthKitTask.title ?? healthKitTask.id
        }
        return task.id
    }
}

// MARK: - Helpers

private extension ManageTasksViewModel {

    func sortTasks(_ tasks: [any OCKAnyTask]) -> [any OCKAnyTask] {
        tasks.sorted { lhs, rhs in
            let lhsTitle = displayTitle(for: lhs)
            let rhsTitle = displayTitle(for: rhs)
            return lhsTitle.localizedCaseInsensitiveCompare(rhsTitle) == .orderedAscending
        }
    }

    func present(error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}

#Preview {
    ManageTasksView()
}
