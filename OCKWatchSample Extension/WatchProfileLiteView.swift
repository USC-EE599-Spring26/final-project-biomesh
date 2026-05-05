//
//  WatchProfileLiteView.swift
//  OCKSample
//
//  Created by Alarik Damrow on 5/2/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
import ParseSwift
import ParseCareKit
import WatchConnectivity

struct WatchProfileLiteView: View {
    @StateObject private var viewModel = WatchPhoneSessionLoginViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.title2)
                            .foregroundStyle(.red)

                        Text("BioMesh")
                            .font(.headline)

                        Text(viewModel.statusText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section {
                    Button("Use iPhone Login") {
                        viewModel.requestLoginFromPhone()
                    }

                    Button("Check Watch Login") {
                        Task {
                            await viewModel.checkCurrentUser()
                        }
                    }

                    if viewModel.isLoggedIn {
                        Button("Log Out", role: .destructive) {
                            Task {
                                await viewModel.logout()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .task {
                viewModel.activateWatchSession()
                await viewModel.checkCurrentUser()

                try? await Task.sleep(nanoseconds: 1_000_000_000)

                if !viewModel.isLoggedIn {
                    viewModel.requestLoginFromPhone()
                }
            }
        }
    }
}

@MainActor
final class WatchPhoneSessionLoginViewModel: NSObject, ObservableObject {
    @Published var statusText = "Checking login..."
    @Published var isLoggedIn = false

    private var isRequestingLogin = false
    private var retryCount = 0
    private let maxRetries = 8

    func activateWatchSession() {
        guard WCSession.isSupported() else {
            statusText = "WatchConnectivity unavailable"
            return
        }

        WCSession.default.delegate = self

        if WCSession.default.activationState != .activated {
            WCSession.default.activate()
        }
    }

    func checkCurrentUser() async {
        do {
            let user = try await User.current()
            statusText = user.username ?? "Signed in on Watch"
            isLoggedIn = true

            try await setupCareKitStoreForCurrentParseUser()
        } catch {
            statusText = "Not signed in on Watch"
            isLoggedIn = false
        }
    }

    func requestLoginFromPhone() {
        guard WCSession.isSupported() else {
            statusText = "WatchConnectivity unavailable"
            return
        }

        guard !isRequestingLogin else { return }

        activateWatchSession()

        guard WCSession.default.activationState == .activated else {
            retryRequestSoon("Activating Watch session...")
            return
        }

        guard WCSession.default.isReachable else {
            retryRequestSoon("Open iPhone app first")
            return
        }

        isRequestingLogin = true
        retryCount = 0
        statusText = "Requesting iPhone login..."

        WCSession.default.sendMessage(
            [Constants.parseUserSessionTokenKey: "request"],
            replyHandler: { reply in
                let token = reply[Constants.parseUserSessionTokenKey] as? String

                Task { @MainActor in
                    self.isRequestingLogin = false

                    guard let token else {
                        self.statusText = "No login from iPhone"
                        self.isLoggedIn = false
                        return
                    }

                    await self.signInWithPhoneSessionToken(token)
                }
            },
            errorHandler: { error in
                let errorText = error.localizedDescription

                Task { @MainActor in
                    self.isRequestingLogin = false
                    self.statusText = "Could not reach iPhone"
                    self.isLoggedIn = false
                    print("Watch login request failed: \(errorText)")
                }
            }
        )
    }

    private func retryRequestSoon(_ message: String) {
        guard retryCount < maxRetries else {
            statusText = "Watch cannot reach iPhone"
            retryCount = 0
            isRequestingLogin = false
            return
        }

        retryCount += 1
        statusText = message

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 750_000_000)
            requestLoginFromPhone()
        }
    }

    private func signInWithPhoneSessionToken(_ sessionToken: String) async {
        do {
            _ = try await User.become(sessionToken: sessionToken)
            try await setupCareKitStoreForCurrentParseUser()

            let user = try await User.current()
            statusText = user.username ?? "Using iPhone Parse login"
            isLoggedIn = true
        } catch {
            statusText = "Watch login failed"
            isLoggedIn = false
            print("Watch Parse login failed: \(error.localizedDescription)")
        }
    }

    private func setupCareKitStoreForCurrentParseUser() async throws {
        guard let appDelegate = AppDelegateKey.defaultValue else {
            throw AppError.couldntBeUnwrapped
        }

        let remoteUUID = try await Utility.getRemoteClockUUID()

        try await appDelegate.setupRemotes(uuid: remoteUUID)

        appDelegate.parseRemote.automaticallySynchronizes = true

        try? await appDelegate.store.synchronize()
    }

    func logout() async {
        do {
            try await User.logout()
            statusText = "Not signed in on Watch"
            isLoggedIn = false
        } catch {
            statusText = "Logout failed"
            print("Watch logout failed: \(error.localizedDescription)")
        }
    }
}

extension WatchPhoneSessionLoginViewModel: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        let errorText = error?.localizedDescription

        Task { @MainActor in
            if let errorText {
                self.statusText = "Watch session failed"
                print("Watch WCSession failed: \(errorText)")
                return
            }

            if activationState == .activated, !self.isLoggedIn {
                self.requestLoginFromPhone()
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        guard let token = message[Constants.parseUserSessionTokenKey] as? String else {
            return
        }

        Task { @MainActor in
            await self.signInWithPhoneSessionToken(token)
        }
    }
}
