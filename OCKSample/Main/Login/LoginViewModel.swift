//
//  LoginViewModel.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import ParseCareKit
import ParseSwift
import os.log
import WatchConnectivity

// swiftlint:disable function_parameter_count
@MainActor
class LoginViewModel: ObservableObject {

    @Published private(set) var isLoggedIn: Bool? {
        willSet {
            objectWillChange.send()
            if newValue != nil {
                self.sendUpdatedUserSessionTokenToWatch()
            }
        }
    }

    @Published private(set) var loginError: ParseError?

    init() {
        Task {
            await checkStatus()
        }
    }

    func checkStatus() async {
        do {
            _ = try await User.current()
            self.isLoggedIn = true
        } catch {
            self.isLoggedIn = false
        }
    }

    private func sendUpdatedUserSessionTokenToWatch() {
        Task {
            do {
                let message = try await Utility.getUserSessionForWatch()
                DispatchQueue.global(qos: .default).async {
                    WCSession.default.sendMessage(
                        message,
                        replyHandler: nil,
                        errorHandler: { error in
                            Logger.remoteSessionDelegate.info(
                                "Could not send updated session token to watch: \(error)"
                            )
                        }
                    )
                }
            } catch {
                Logger.login.info("Could not get session token for watch: \(error)")
            }
        }
    }

    private func finishCompletingSignIn(
        _ careKitPatient: OCKPatient? = nil
    ) async throws {
        if let careKitUser = careKitPatient {
            var user = try await User.current()
            guard let userType = careKitUser.userType,
                  let remoteUUID = careKitUser.remoteClockUUID else {
                return
            }

            user.lastTypeSelected = userType.rawValue
            if user.userTypeUUIDs != nil {
                user.userTypeUUIDs?[userType.rawValue] = remoteUUID
            } else {
                user.userTypeUUIDs = [userType.rawValue: remoteUUID]
            }

            do {
                _ = try await user.save()
            } catch {
                Logger.login.info("Could not save updated user: \(error)")
            }
        }

        await checkStatus()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NotificationCenter.default.post(
                .init(name: Notification.Name(rawValue: Constants.requestSync))
            )
            Utility.requestHealthKitPermissions()
        }

        await Utility.updateInstallationWithDeviceToken()
    }

    private func savePatientAfterSignUp(
        _ type: UserType,
        firstName: String,
        lastName: String
    ) async throws -> OCKPatient {

        let remoteUUID = UUID()
        do {
            try await Utility.setDefaultACL()
        } catch {
            Logger.login.error("Could not set defaultACL: \(error)")
        }

        guard let appDelegate = AppDelegateKey.defaultValue else {
            throw AppError.couldntBeUnwrapped
        }

        try await appDelegate.setupRemotes(uuid: remoteUUID)

        var newPatient = OCKPatient(
            remoteUUID: remoteUUID,
            id: remoteUUID.uuidString,
            givenName: firstName,
            familyName: lastName
        )
        newPatient.userType = type

        let savedPatient = try await appDelegate.store.addPatient(newPatient)

        // Create a contact for the signed-up user
        let newContact = OCKContact(
            id: remoteUUID.uuidString,
            name: newPatient.name,
            carePlanUUID: nil
        )

        // This is a new contact that has never been saved before
        _ = try await appDelegate.store.addAnyContact(newContact)

        let currentDate = Date()
        let startDate = daysInThePastToGenerateSampleData < 0
            ? Calendar.current.date(
                byAdding: .day,
                value: daysInThePastToGenerateSampleData,
                to: currentDate
            )!
            : currentDate

        // Tie the saved patient to the seeded care plans and tasks
        try await appDelegate.store.populateDefaultCarePlansTasksContacts(
            patientUUID: savedPatient.uuid,
            startDate: startDate
        )

        // Tie HealthKit tasks to the same patient-owned care plans
        try await appDelegate.healthKitStore.populateDefaultHealthKitTasks(
            savedPatient.uuid,
            startDate: startDate
        )

        if startDate < currentDate {
            try await appDelegate.store.populateSampleOutcomes(
                startDate: startDate
            )
        }

        appDelegate.parseRemote.automaticallySynchronizes = true

        NotificationCenter.default.post(
            .init(name: Notification.Name(rawValue: Constants.requestSync))
        )
        Logger.login.info("Successfully added a new Patient")

        return savedPatient
    }

    func signup(
        _ type: UserType,
        username: String,
        password: String,
        email: String,
        firstName: String,
        lastName: String
    ) async {
        do {
            guard try await PCKUtility.isServerAvailable() else {
                Logger.login.error("Server health is not \"ok\"")
                return
            }

            var newUser = User()
            newUser.username = username.lowercased()
            newUser.password = password
            newUser.email = email

            let user = try await newUser.signup()
            Logger.login.info("Parse signup successful: \(user)")

            let patient = try await savePatientAfterSignUp(
                type,
                firstName: firstName,
                lastName: lastName
            )
            try? await finishCompletingSignIn(patient)
        } catch {
            Logger.login.error("Error details: \(error)")
            guard let parseError = error as? ParseError else {
                return
            }

            switch parseError.code {
            case .usernameTaken:
                self.loginError = parseError
            default:
                Logger.login.error("*** Error Signing up as user for Parse Server. Are you running parse-hipaa and is the initialization complete? Check http://localhost:1337 in your browser. If you are still having problems check for help here: https://github.com/netreconlab/parse-postgres#getting-started ***")
                self.loginError = parseError
            }
        }
    }

    func login(
        username: String,
        password: String
    ) async {
        do {
            guard try await PCKUtility.isServerAvailable() else {
                Logger.login.error("Server health is not \"ok\"")
                return
            }

            let user = try await User.login(
                username: username.lowercased(),
                password: password
            )
            Logger.login.info("Parse login successful: \(user, privacy: .private)")
            AppDelegateKey.defaultValue?.setFirstTimeLogin(true)

            do {
                try await Utility.setupRemoteAfterLogin()
                try await finishCompletingSignIn()
            } catch {
                Logger.login.error("Error saving the patient after signup: \(error, privacy: .public)")
            }
        } catch {
            Logger.login.error("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
            Logger.login.error("Error details: \(error)")

            guard let parseError = error as? ParseError else {
                return
            }
            self.loginError = parseError
        }
    }

    func loginAnonymously() async {
        do {
            guard try await PCKUtility.isServerAvailable() else {
                Logger.login.error("Server health is not \"ok\"")
                return
            }

            let user = try await User.anonymous.login()
            Logger.login.info("Parse login anonymous successful: \(user)")

            let patient = try await savePatientAfterSignUp(
                .patient,
                firstName: "Anonymous",
                lastName: "Login"
            )
            try? await finishCompletingSignIn(patient)
        } catch {
            Logger.login.error("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
            Logger.login.error("Error details: \(String(describing: error))")

            guard let parseError = error as? ParseError else {
                return
            }
            self.loginError = parseError
        }
    }

    func logout() async {
        await Utility.logoutAndResetAppState()
        await self.checkStatus()
    }
}
