//
//  OCKWatchSampleApp.swift
//  OCKWatchSample Extension
//
//  Created by Corey Baker on 6/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import WatchKit
import SwiftUI
import CareKit
import CareKitStore
import CareKitUI

@main
struct OCKWatchSampleApp: App {
    @WKApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @Environment(\.customStyler) private var style

    @SceneBuilder var body: some Scene {
        WindowGroup {
            WatchMainView()
                .environment(\.appDelegate, appDelegate)
                .environment(\.careStore, appDelegate.storeCoordinator)
                .careKitStyle(style)
        }

        WKNotificationScene(
            controller: NotificationController.self,
            category: "myCategory"
        )
    }
}
