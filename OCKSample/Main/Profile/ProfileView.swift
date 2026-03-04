//
//  ProfileView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import CareKitUI
import os.log
import SwiftUI

struct ProfileView: View {

    @CareStoreFetchRequest(query: query()) private var patients
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject var loginViewModel: LoginViewModel

    private enum ActiveSheet: Identifiable {
        case addTask
        case manageTasks

        var id: Int { hashValue }
    }

    @State private var activeSheet: ActiveSheet?

    var body: some View {
        NavigationView {
            VStack {
                profileFields

                saveProfileButton
                logoutButton
            }
            .navigationTitle("Profile")
            .toolbar { toolbarContent }
            .sheet(item: $activeSheet) { sheet in
                sheetView(for: sheet)
            }
            .onReceive(patients.publisher) { publishedPatient in
                viewModel.updatePatient(publishedPatient.result)
            }
        }
    }
}

// MARK: - Subviews

private extension ProfileView {

    var profileFields: some View {
        VStack(alignment: .leading) {
            TextField("GIVEN_NAME", text: $viewModel.firstName)
                .padding()
                .cornerRadius(20.0)
                .shadow(radius: 10.0, x: 20, y: 10)

            TextField("FAMILY_NAME", text: $viewModel.lastName)
                .padding()
                .cornerRadius(20.0)
                .shadow(radius: 10.0, x: 20, y: 10)

            DatePicker(
                "BIRTHDAY",
                selection: $viewModel.birthday,
                displayedComponents: [.date]
            )
            .padding()
            .cornerRadius(20.0)
            .shadow(radius: 10.0, x: 20, y: 10)
        }
    }

    var saveProfileButton: some View {
        Button {
            Task {
                do {
                    try await viewModel.saveProfile()
                } catch {
                    Logger.profile.error("Error saving profile: \(error)")
                }
            }
        } label: {
            Text("SAVE_PROFILE")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(width: 300, height: 50)
        }
        .background(Color(.green))
        .cornerRadius(15)
    }

    var logoutButton: some View {
        Button {
            Task { await loginViewModel.logout() }
        } label: {
            Text("LOG_OUT")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(width: 300, height: 50)
        }
        .background(Color(.red))
        .cornerRadius(15)
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button { activeSheet = .addTask } label: {
                Image(systemName: "plus.circle.fill")
            }

            Button { activeSheet = .manageTasks } label: {
                Image(systemName: "trash.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .addTask:
            AddTaskView()
        case .manageTasks:
            ManageTasksView()
        }
    }
}

// MARK: - Queries

private extension ProfileView {
    static func query() -> OCKPatientQuery {
        OCKPatientQuery(for: Date())
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(loginViewModel: .init())
            .environment(\.careStore, Utility.createPreviewStore())
    }
}
