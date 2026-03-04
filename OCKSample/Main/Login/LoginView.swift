//
//  LoginView.swift
//  OCKSample
//
//  Created by Corey Baker on 10/29/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

/*
 This is a variation of the tutorial found here:
 https://www.iosapptemplates.com/blog/swiftui/login-screen-swiftui
 */

import ParseSwift
import SwiftUI
import UIKit

/*
 Anything is @ is a wrapper that subscribes and refreshes
 the view when a change occurs. List to the last lecture
 in Section 2 for an explanation
 */

struct LoginView: View {
    @Environment(\.tintColorFlip) private var tintColorFlip
    @ObservedObject var viewModel: LoginViewModel

    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var signupLoginSegmentValue = 0

    var body: some View {
        VStack {
            header

            loginSignupPicker

            credentialFields

            primaryActionButton

            anonymousLoginButton

            loginErrorText

            Spacer()
        }
        .background(backgroundGradient)
    }
}

// MARK: - Subviews

private extension LoginView {

    var header: some View {
        VStack {
            Text("BioMesh")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()

            Image("exercise.jpg")
                .resizable()
                .frame(width: 150, height: 150, alignment: .center)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(.white), lineWidth: 4))
                .shadow(radius: 10)
                .padding()
        }
    }

    var loginSignupPicker: some View {
        Picker(selection: $signupLoginSegmentValue, label: Text("LOGIN_PICKER")) {
            Text("LOGIN").tag(0)
            Text("SIGN_UP").tag(1)
        }
        .pickerStyle(.segmented)
        .background(Color(tintColorFlip))
        .cornerRadius(20.0)
        .padding()
    }

    var credentialFields: some View {
        VStack(alignment: .leading) {
            TextField("USERNAME", text: $username)
                .padding()
                .background(.white)
                .cornerRadius(20.0)
                .shadow(radius: 10.0, x: 20, y: 10)

            SecureField("PASSWORD", text: $password)
                .padding()
                .background(.white)
                .cornerRadius(20.0)
                .shadow(radius: 10.0, x: 20, y: 10)

            if isSignupMode {
                signupFields
            }
        }
        .padding()
    }

    var signupFields: some View {
        Group {
            TextField("GIVEN_NAME", text: $firstName)
                .padding()
                .background(.white)
                .cornerRadius(20.0)
                .shadow(radius: 10.0, x: 20, y: 10)

            TextField("FAMILY_NAME", text: $lastName)
                .padding()
                .background(.white)
                .cornerRadius(20.0)
                .shadow(radius: 10.0, x: 20, y: 10)

            TextField("EMAIL", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding()
                .background(.white)
                .cornerRadius(20.0)
                .shadow(radius: 10.0, x: 20, y: 10)
        }
    }

    var primaryActionButton: some View {
        Button {
            Task { await performPrimaryAction() }
        } label: {
            Text(isSignupMode ? "SIGN_UP" : "LOGIN")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(width: 300)
        }
        .background(Color(.green))
        .cornerRadius(15)
    }

    var anonymousLoginButton: some View {
        Button {
            Task { await viewModel.loginAnonymously() }
        } label: {
            if !isSignupMode {
                Text("LOGIN_ANONYMOUSLY")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 300)
            } else {
                EmptyView()
            }
        }
        .background(Color(.lightGray))
        .cornerRadius(15)
    }

    @ViewBuilder
    var loginErrorText: some View {
        if let loginError = viewModel.loginError {
            Text("\(String(localized: "ERROR")): \(loginError.message)")
                .foregroundColor(.red)
        }
    }

    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(
                colors: [
                    Color(tintColorFlip),
                    Color.accentColor
                ]
            ),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var isSignupMode: Bool {
        signupLoginSegmentValue == 1
    }
}

// MARK: - Actions

private extension LoginView {

    func performPrimaryAction() async {
        if isSignupMode {
            await viewModel.signup(
                .patient,
                username: username,
                password: password,
                email: email,
                firstName: firstName,
                lastName: lastName
            )
        } else {
            await viewModel.login(
                username: username,
                password: password
            )
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: .init())
    }
}
