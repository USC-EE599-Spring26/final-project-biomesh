//
//  ProfileView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

//
//  ProfileView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKitUI
import CareKitStore
import CareKit
import os.log
import SwiftUI

struct ProfileView: View {

    @CareStoreFetchRequest(query: ProfileViewModel.queryPatient()) private var patients
    @CareStoreFetchRequest(query: ProfileViewModel.queryContacts()) private var contacts
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject var loginViewModel: LoginViewModel

    // MARK: Navigation
    @State var isPresentingAddTask = false
    @State var isShowingSaveAlert = false
    @State var isPresentingContact = false
    @State var isPresentingImagePicker = false

    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    ProfileImageView(viewModel: viewModel)
                    Form {
                        Section(header: Text("About")) {
                            TextField("First Name", text: $viewModel.firstName)
                                .padding()
                                .cornerRadius(20.0)
                                .shadow(radius: 10.0, x: 20, y: 10)

                            TextField("Last Name", text: $viewModel.lastName)
                                .padding()
                                .cornerRadius(20.0)
                                .shadow(radius: 10.0, x: 20, y: 10)

                            TextField("Note", text: $viewModel.note)
                                .padding()
                                .cornerRadius(20.0)
                                .shadow(radius: 10.0, x: 20, y: 10)

                            DatePicker(
                                "Birthday",
                                selection: $viewModel.birthday,
                                displayedComponents: [.date]
                            )

                            Picker(
                                "Sex",
                                selection: Binding<String>(
                                    get: {
                                        switch viewModel.sex {
                                        case .male:
                                            return "male"
                                        case .female:
                                            return "female"
                                        case .other:
                                            return "other"
                                        @unknown default:
                                            return "other"
                                        }
                                    },
                                    set: { (newValue: String) in
                                        switch newValue {
                                        case "male":
                                            viewModel.sex = .male
                                        case "female":
                                            viewModel.sex = .female
                                        default:
                                            viewModel.sex = .other(viewModel.sexOtherField)
                                        }
                                    }
                                )
                            ) {
                                Text("Male").tag("male")
                                Text("Female").tag("female")
                                Text("Other").tag("other")
                            }

                            if case .other = viewModel.sex {
                                TextField("Specify sex", text: $viewModel.sexOtherField)
                                    .onChange(of: viewModel.sexOtherField) { newValue in
                                        viewModel.sex = .other(newValue.isEmpty ? "other" : newValue)
                                    }
                            }

                            TextField("Allergies", text: $viewModel.allergies)
                                .padding()
                                .cornerRadius(20.0)
                                .shadow(radius: 10.0, x: 20, y: 10)
                        }

                        Section(header: Text("Contact")) {
                            TextField("Street", text: $viewModel.street)
                            TextField("City", text: $viewModel.city)
                            TextField("State", text: $viewModel.state)
                            TextField("Postal code", text: $viewModel.zipcode)
                            TextField("Email", text: $viewModel.email)
                            TextField("Messaging Number", text: $viewModel.messagingNumber)
                            TextField("Phone Number", text: $viewModel.phoneNumber)
                            TextField("Other Contact Info", text: $viewModel.otherContactInfo)
                        }
                    }
                }

                Button(action: {
                    Task {
                        await viewModel.saveProfile()
                    }
                }, label: {
                    Text("Save Profile")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 50)
                })
                .background(Color(.green))
                .cornerRadius(15)

                // Notice that "action" is a closure (which is essentially
                // a function as argument like we discussed in class)
                Button(action: {
                    Task {
                        await loginViewModel.logout()
                    }
                }, label: {
                    Text("Log Out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 50)
                })
                .background(Color(.red))
                .cornerRadius(15)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("My Contact") {
                        viewModel.isPresentingContact = true
                    }
                    .sheet(isPresented: $viewModel.isPresentingContact) {
                        MyContactView()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Task") {
                        isPresentingAddTask = true
                    }
                    .sheet(isPresented: $isPresentingAddTask) {
                        CareKitTaskView()
                    }
                }
            }
            .sheet(isPresented: $viewModel.isPresentingImagePicker) {
                ImagePicker(image: $viewModel.profileUIImage)
            }
            .alert(isPresented: $viewModel.isShowingSaveAlert) {
                return Alert(title: Text("Update"),
                             message: Text(viewModel.alertMessage),
                             dismissButton: .default(Text("Ok"), action: {
                                viewModel.isShowingSaveAlert = false
                             }))
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
            .accentColor(Color.accentColor)
            .environment(\.careStore, Utility.createPreviewStore())
    }
}
