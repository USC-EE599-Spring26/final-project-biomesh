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

    #if os(iOS)
    @State private var isPresentingAddTask = false
    @State private var isPresentingManageTasks = false
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: layoutSpacing) {
                    #if os(iOS)
                    topBar
                    #endif

                    titleView

                    ProfileImageView(viewModel: viewModel)
                        .frame(maxWidth: .infinity)

                    aboutSection

                    #if os(iOS)
                    contactSection
                    #endif

                    actionButtons
                }
                .padding(.vertical, verticalPadding)
            }
            .background(backgroundColor)
            .profileSheets(
                viewModel: viewModel,
                isPresentingManageTasks: bindingForManageTasks,
                isPresentingAddTask: bindingForAddTask
            )
            .alert(isPresented: $viewModel.isShowingSaveAlert) {
                Alert(
                    title: Text("Update"),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("Ok")) {
                        viewModel.isShowingSaveAlert = false
                    }
                )
            }
            .navigationTitle(navigationTitle)
            #if os(watchOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .onReceive(patients.publisher) { publishedPatient in
            viewModel.updatePatient(publishedPatient.result)
        }
        .onReceive(contacts.publisher) { publishedContact in
            viewModel.updateContact(publishedContact.result)
        }
    }

    // MARK: - Main sections

    private var titleView: some View {
        Text("Profile")
            .font(titleFont)
            .padding(.horizontal, horizontalPadding)
            #if os(watchOS)
            .frame(maxWidth: .infinity, alignment: .center)
            #endif
    }

    private var aboutSection: some View {
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
            .padding(.vertical, rowVerticalPadding)

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
            .padding(.vertical, rowVerticalPadding)

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
    }

    #if os(iOS)
    private var contactSection: some View {
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
    }
    #endif

    // MARK: - iOS top bar

    #if os(iOS)
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
    #endif

    // MARK: - Reusable views

    private func profileSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: sectionTitleSpacing) {
            Text(title)
                .font(sectionTitleFont)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, sectionHorizontalPadding)
            .padding(.vertical, sectionVerticalPadding)
            .background(sectionBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: sectionCornerRadius, style: .continuous))
        }
        .padding(.horizontal, horizontalPadding)
    }

    private func profileRowField(
        _ title: String,
        text: Binding<String>
    ) -> some View {
        TextField(title, text: text)
            .textFieldStyle(.plain)
            .padding(.vertical, rowVerticalPadding)
    }

    private var actionButtons: some View {
        VStack(spacing: buttonSpacing) {
            Button {
                Task {
                    await viewModel.saveProfile()
                }
            } label: {
                Text("Save Profile")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, buttonVerticalPadding)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: buttonCornerRadius, style: .continuous))
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
                    .padding(.vertical, buttonVerticalPadding)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: buttonCornerRadius, style: .continuous))
            }
        }
        .padding(.horizontal, horizontalPadding)
    }

    #if os(iOS)
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
    #endif
}

// MARK: - Platform layout

private extension ProfileView {

    var navigationTitle: String {
        #if os(watchOS)
        "Profile"
        #else
        ""
        #endif
    }

    var layoutSpacing: CGFloat {
        #if os(watchOS)
        12
        #else
        22
        #endif
    }

    var verticalPadding: CGFloat {
        #if os(watchOS)
        8
        #else
        12
        #endif
    }

    var horizontalPadding: CGFloat {
        #if os(watchOS)
        8
        #else
        20
        #endif
    }

    var titleFont: Font {
        #if os(watchOS)
        .headline
        #else
        .system(size: 34, weight: .bold)
        #endif
    }

    var sectionTitleFont: Font {
        #if os(watchOS)
        .footnote.weight(.semibold)
        #else
        .system(size: 18, weight: .semibold)
        #endif
    }

    var sectionTitleSpacing: CGFloat {
        #if os(watchOS)
        6
        #else
        12
        #endif
    }

    var sectionHorizontalPadding: CGFloat {
        #if os(watchOS)
        10
        #else
        18
        #endif
    }

    var sectionVerticalPadding: CGFloat {
        #if os(watchOS)
        6
        #else
        10
        #endif
    }

    var sectionCornerRadius: CGFloat {
        #if os(watchOS)
        16
        #else
        28
        #endif
    }

    var rowVerticalPadding: CGFloat {
        #if os(watchOS)
        8
        #else
        14
        #endif
    }

    var buttonSpacing: CGFloat {
        #if os(watchOS)
        8
        #else
        14
        #endif
    }

    var buttonVerticalPadding: CGFloat {
        #if os(watchOS)
        10
        #else
        16
        #endif
    }

    var buttonCornerRadius: CGFloat {
        #if os(watchOS)
        14
        #else
        18
        #endif
    }

    var backgroundColor: Color {
        #if os(watchOS)
        Color.clear
        #else
        Color(.systemGroupedBackground)
        #endif
    }

    var sectionBackgroundColor: Color {
        #if os(watchOS)
        Color.gray.opacity(0.18)
        #else
        Color.white
        #endif
    }
}

// MARK: - iOS-only sheet helpers

private extension ProfileView {

    var bindingForManageTasks: Binding<Bool> {
        #if os(iOS)
        $isPresentingManageTasks
        #else
        .constant(false)
        #endif
    }

    var bindingForAddTask: Binding<Bool> {
        #if os(iOS)
        $isPresentingAddTask
        #else
        .constant(false)
        #endif
    }
}

private extension View {
    @ViewBuilder
    func profileSheets(
        viewModel: ProfileViewModel,
        isPresentingManageTasks: Binding<Bool>,
        isPresentingAddTask: Binding<Bool>
    ) -> some View {
        #if os(iOS)
        self
            .sheet(
                isPresented: Binding(
                    get: { viewModel.isPresentingImagePicker },
                    set: { viewModel.isPresentingImagePicker = $0 }
                )
            ) {
                ImagePicker(
                    image: Binding(
                        get: { viewModel.profileUIImage },
                        set: { viewModel.profileUIImage = $0 }
                    )
                )
            }
            .sheet(
                isPresented: Binding(
                    get: { viewModel.isPresentingContact },
                    set: { viewModel.isPresentingContact = $0 }
                )
            ) {
                MyContactView()
            }
            .sheet(isPresented: isPresentingManageTasks) {
                ManageTasksView()
            }
            .sheet(isPresented: isPresentingAddTask) {
                AddTaskView()
            }
        #else
        self
        #endif
    }
}

// MARK: - Previews

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(loginViewModel: .init())
            .environment(\.careStore, Utility.createPreviewStore())
    }
}
