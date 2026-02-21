//
//  ProfileView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//
import CareKitUI
import CareKitStore
import CareKit
import CareKitEssentials
import os.log
import SwiftUI
struct ProfileView: View {
    @Environment(\.careStore) private var careStore
    @CareStoreFetchRequest(query: Self.patientQuery()) private var patients
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject var loginViewModel: LoginViewModel
    let storeCoordinator: OCKStoreCoordinator
    private enum ActiveSheet: Identifiable {
        case addTask
        case manageTasks
        var id: Int { hashValue }
    }
    @State private var activeSheet: ActiveSheet?
    init(loginViewModel: LoginViewModel, storeCoordinator: OCKStoreCoordinator) {
        self.loginViewModel = loginViewModel
        self.storeCoordinator = storeCoordinator
    }
    var body: some View {
        NavigationStack {
            VStack {
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
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { activeSheet = .addTask } label: {
                        Image(systemName: "plus")
                    }

                    Button { activeSheet = .manageTasks } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addTask:
                    if let app = AppDelegateKey.defaultValue {
                        CreateTaskView(
                            store: app.store,
                            healthKitStore: app.healthKitStore
                        )
                    } else {
                        Text("App not ready yet.")
                            .padding()
                    }
                case .manageTasks:
                    if let app = AppDelegateKey.defaultValue {
                        ManageTasksView(taskStore: app.store)
                    } else {
                        Text("App not ready yet.")
                            .padding()
                    }
                }
            }
            .onReceive(patients.publisher) { publishedPatient in
                viewModel.updatePatient(publishedPatient.result)
            }
        }
    }
    static func patientQuery() -> OCKPatientQuery {
        OCKPatientQuery(for: Date())
    }
}
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(loginViewModel: .init(),
                    storeCoordinator: OCKStoreCoordinator())
        .environment(\.careStore, Utility.createPreviewStore())
    }
}
