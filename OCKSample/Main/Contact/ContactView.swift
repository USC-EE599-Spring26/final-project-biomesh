//
//  ContactView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitEssentials
import CareKitStore
import os.log
import SwiftUI
import UIKit

#if os(iOS) && !os(visionOS)
struct ContactView: UIViewControllerRepresentable {
    @Environment(\.careStore) private var careStore
    @CareStoreFetchRequest(query: Self.query()) private var contacts

    func makeUIViewController(context: Context) -> UINavigationController {
        UINavigationController(rootViewController: createViewController())
    }

    func updateUIViewController(
        _ uiViewController: UINavigationController,
        context: Context
    ) {
        uiViewController.setViewControllers([createViewController()], animated: false)
    }

    private func createViewController() -> UIViewController {
        let currentContacts = contacts.latest

        return CustomContactViewController(
            store: careStore,
            contacts: currentContacts,
            viewSynchronizer: OCKSimpleContactViewSynchronizer()
        )
    }

    static func query() -> OCKContactQuery {
        OCKContactQuery(for: Date())
    }
}

struct ContactView_Previews: PreviewProvider {
    static var previews: some View {
        ContactView()
            .environment(\.careStore, Utility.createPreviewStore())
            .careKitStyle(Styler())
    }
}
#else
struct ContactView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Contacts Unavailable",
                systemImage: "person.2.slash",
                description: Text("This contact interface is only available on iOS.")
            )
            .navigationTitle("Contacts")
        }
    }
}

struct ContactView_Previews: PreviewProvider {
    static var previews: some View {
        ContactView()
            .careKitStyle(Styler())
    }
}
#endif
