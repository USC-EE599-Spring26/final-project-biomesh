//
//  ProfileView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import SwiftUI

struct ProfileView: View {
    @CareStoreFetchRequest(query: ProfileViewModel.queryPatient()) private var patients
    @CareStoreFetchRequest(query: ProfileViewModel.queryContacts()) private var contacts
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject var loginViewModel: LoginViewModel

    var body: some View {
        NavigationView {
            VStack {
                ProfileImageView(viewModel: viewModel)

                Form {
                    Section(header: Text("About")) {
                        TextField("First Name", text: $viewModel.firstName)
                        TextField("Last Name", text: $viewModel.lastName)

                        DatePicker(
                            "Birthday",
                            selection: $viewModel.birthday,
                            displayedComponents: [.date]
                        )
                    }

                    Section(header: Text("Contact")) {
                        TextField("Street", text: $viewModel.street)
                        TextField("City", text: $viewModel.city)
                        TextField("State", text: $viewModel.state)
                        TextField("Postal Code", text: $viewModel.zipcode)
                        TextField("Country", text: $viewModel.country)
                    }

                    Section {
                        Button("Save Profile") {
                            Task {
                                await viewModel.saveProfile()
                            }
                        }
                        .frame(maxWidth: .infinity)

                        Button("Log Out", role: .destructive) {
                            Task {
                                await loginViewModel.logout()
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("My Contact") {
                        viewModel.isPresentingContact = true
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Task") {
                        viewModel.isPresentingAddTask = true
                    }
                }
            }
            .sheet(isPresented: $viewModel.isPresentingContact) {
                MyContactView()
            }
            .sheet(isPresented: $viewModel.isPresentingAddTask) {
                AddTaskView()
            }
            .sheet(isPresented: $viewModel.isPresentingImagePicker) {
                ImagePicker(image: $viewModel.profileUIImage)
            }
            .alert("Update", isPresented: $viewModel.isShowingSaveAlert) {
                Button("OK") {
                    viewModel.isShowingSaveAlert = false
                }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
        .onReceive(patients.publisher) { publishedPatient in
            viewModel.updatePatient(publishedPatient.result)
        }
        .onReceive(contacts.publisher) { publishedContact in
            viewModel.updateContact(publishedContact.result)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(loginViewModel: .init())
            .environment(\.careStore, Utility.createPreviewStore())
    }
}
