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

    // MARK: Navigation
    @State var isPresentingAddTask = false
    @State var isPresentingManageTasks = false
    @State var isShowingSaveAlert = false
    @State var isPresentingContact = false
    @State var isPresentingImagePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    topBar

                    Text("Profile")
                        .font(.system(size: 34, weight: .bold))
                        .padding(.horizontal, 20)

                    ProfileImageView(viewModel: viewModel)
                        .frame(maxWidth: .infinity)

                    profileSection(title: "About") {
                        profileRowField("First Name", text: $viewModel.firstName)
                        Divider()
                        profileRowField("Last Name", text: $viewModel.lastName)
                        Divider()
                        profileRowField("Note", text: $viewModel.note)
                        Divider()
                        DatePicker(
                            "Birthday",
                            selection: $viewModel.birthday,
                            displayedComponents: [.date]
                        )
                        Divider()
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
                                set: { newValue in
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
                            Divider()
                            profileRowField("Specify sex", text: $viewModel.sexOtherField)
                                .onChange(of: viewModel.sexOtherField) { newValue in
                                    viewModel.sex = .other(newValue.isEmpty ? "other" : newValue)
                                }
                        }

                        Divider()
                        profileRowField("Allergies", text: $viewModel.allergies)
                    }

                    profileSection(title: "Contact") {
                        profileRowField("Street", text: $viewModel.street)
                        Divider()
                        profileRowField("City", text: $viewModel.city)
                        Divider()
                        profileRowField("State", text: $viewModel.state)
                        Divider()
                        profileRowField("Postal code", text: $viewModel.zipcode)
                        Divider()
                        profileRowField("Email", text: $viewModel.emailAddress)
                        Divider()
                        profileRowField("Messaging Number", text: $viewModel.messagingNumber)
                        Divider()
                        profileRowField("Phone Number", text: $viewModel.phoneNumber)
                        Divider()
                        profileRowField("Other Contact Info", text: $viewModel.otherContactInfo)
                    }

                    actionButtons
                }
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $viewModel.isPresentingImagePicker) {
                ImagePicker(image: $viewModel.profileUIImage)
            }
            .sheet(isPresented: $viewModel.isPresentingContact) {
                .padding(.vertical, 12)
            }
            .sheet(isPresented: $isPresentingManageTasks) {
                ManageTasksView()
            }
            .sheet(isPresented: $isPresentingAddTask) {
                AddTaskView()
            }
            .alert(isPresented: $viewModel.isShowingSaveAlert) {
                Alert(
                    title: Text("Update"),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("Ok"), action: {
                        viewModel.isShowingSaveAlert = false
                    })
                )
            }
        }
        .onReceive(patients.publisher) { publishedPatient in
            viewModel.updatePatient(publishedPatient.result)
        }
        .onReceive(contacts.publisher) { publishedContact in
            viewModel.updateContact(publishedContact.result)
        }
    }

    private var topBar: some View {
        HStack {
            Button("My Contact") {
                viewModel.isPresentingContact = true
            }
            .font(.system(size: 16, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white)
            .clipShape(Capsule())

            Spacer()

            HStack(spacing: 12) {
                circleIconButton(
                    systemName: "plus",
                    foreground: .white,
                    background: .black
                ) {
                    isPresentingAddTask = true
                }

                circleIconButton(
                    systemName: "trash",
                    foreground: .white,
                    background: .red
                ) {
                    isPresentingManageTasks = true
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
    }

    private func profileSection<Content: View>(
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

    private func profileRowField(
        _ title: String,
        text: Binding<String>
    ) -> some View {
        TextField(title, text: text)
            .textFieldStyle(.plain)
            .padding(.vertical, 14)
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            Button {
                Task {
                    await viewModel.saveProfile()
                }
            } label: {
                Text("Save Profile")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Button {
                Task {
                    await loginViewModel.logout()
                }
            } label: {
                Text("Log Out")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(.horizontal, 20)
    }

    private func circleIconButton(
        systemName: String,
        foreground: Color,
        background: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(foreground)
                .frame(width: 36, height: 36)
                .background(background)
                .clipShape(Circle())
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
