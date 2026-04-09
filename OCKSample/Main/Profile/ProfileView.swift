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

    @CareStoreFetchRequest(query: ProfileViewModel.queryPatient()) private var patients
    @CareStoreFetchRequest(query: ProfileViewModel.queryContacts()) private var contacts
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
                VStack {
                    ProfileImageView(viewModel: viewModel)
                    Form {
                        Section(header: Text("About")) {
                            TextField("First Name",
                                      text: $viewModel.firstName)
                            TextField("Last Name",
                                      text: $viewModel.lastName)
                            TextField("Note",
                                      text: $viewModel.note)
                            DatePicker("Birthday",
                                       selection: $viewModel.birthday,
                                       displayedComponents: [DatePickerComponents.date])
                            Picker("Sex", selection: $viewModel.sex) {
                                Text("Female").tag(OCKBiologicalSex.female)
                                Text("Male").tag(OCKBiologicalSex.male)
                                Text("Other").tag(OCKBiologicalSex.other("other"))
                            }
                        }

                        Section(header: Text("Contact")) {
                            TextField("Street", text: $viewModel.street)
                            TextField("City", text: $viewModel.city)
                            TextField("State", text: $viewModel.state)
                            TextField("Postal code", text: $viewModel.zipcode)
                        }
                    }
                }

                saveProfileButton
                logoutButton
            }
            .navigationTitle("Profile")
            .toolbar { toolbarContent }
            .sheet(item: $activeSheet) { sheet in
                sheetView(for: sheet)
            }
            .sheet(isPresented: $viewModel.isPresentingImagePicker) {
                ImagePicker(image: $viewModel.profileUIImage)
            }
            .alert(isPresented: $viewModel.isShowingSaveAlert) {
                Alert(title: Text("Update"),
                      message: Text(viewModel.alertMessage),
                      dismissButton: .default(Text("Ok"), action: {
                          viewModel.isShowingSaveAlert = false
                      }))
            }
            .onReceive(patients.publisher) { publishedPatient in
                viewModel.updatePatient(publishedPatient.result)
            }
            .onReceive(contacts.publisher) { publishedContact in
                viewModel.updateContact(publishedContact.result)
            }
        }
    }
}

// MARK: - Subviews

private extension ProfileView {

    var saveProfileButton: some View {
        Button {
            Task {
                await viewModel.saveProfile()
            }
        } label: {
            Text("Save Profile")
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
            Text("Log Out")
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
        ToolbarItem(placement: .navigationBarLeading) {
            Button("My Contact") {
                viewModel.isPresentingContact = true
            }
            .sheet(isPresented: $viewModel.isPresentingContact) {
                MyContactView()
            }
        }
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

// MARK: - Previews

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(loginViewModel: .init())
            .environment(\.careStore, Utility.createPreviewStore())
    }
}
