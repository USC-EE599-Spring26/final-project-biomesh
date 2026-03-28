//
//  AppDelegate+UIApplicationDelegate.swift
//  OCKSample
//
//  Created by Corey Baker on 9/19/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import UIKit
import ParseCareKit
import ParseSwift
import os.log
import CareKitStore

extension AppDelegate: UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Task {
            if isSyncingWithRemote {
                await configureRemoteStartup()
            } else {
                await configureLocalStartup()
            }
        }

        return true
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {}

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task {
            await Utility.updateInstallationWithDeviceToken(deviceToken)
        }
    }
}

private extension AppDelegate {

    func configureRemoteStartup() async {
        do {
            try await PCKUtility.configureParse(fileName: Constants.parseConfigFileName) { _, completionHandler in
                completionHandler(.performDefaultHandling, nil)
            }
        } catch {
            Logger.appDelegate.info("Could not configure Parse Swift: \(error)")
            return
        }

        await Utility.clearDeviceOnFirstRun()

        do {
            _ = try await User.current()
            Logger.appDelegate.info("User is already signed in...")

            do {
                let uuid = try await Utility.getRemoteClockUUID()
                try await setupRemotes(uuid: uuid)
                parseRemote.automaticallySynchronizes = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    NotificationCenter.default.post(
                        .init(name: Notification.Name(rawValue: Constants.requestSync))
                    )
                }
            } catch {
                Logger.appDelegate.error("User is logged in, but missing remoteId: \(error)")
                do {
                    try await setupRemotes()
                } catch {
                    Logger.appDelegate.error("Could not setup remotes without remoteId: \(error)")
                }
            }
        } catch {
            Logger.appDelegate.error("User is not logged in: \(error)")
        }
    }

    func configureLocalStartup() async {
        await Utility.clearDeviceOnFirstRun()

        do {
            try await setupRemotes()

            var query = OCKPatientQuery(for: Date())
            if let patient = try? await store.fetchPatients(query: query).first {
                try await store.populateDefaultCarePlansTasksContacts(
                    patientUUID: patient.uuid
                )
            } else {
                try await store.populateDefaultCarePlansTasksContacts(
                    patientUUID: nil
                )
            }

            try await healthKitStore.populateDefaultHealthKitTasks()
        } catch {
            Logger.appDelegate.error("""
                Could not populate
                data stores: \(error)
            """)
        }
    }
}
