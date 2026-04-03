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
    @Environment(\.careStore) var careStore
    @CareStoreFetchRequest(query: Self.query()) private var contacts

    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = createViewController()
        return UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(
        _ uiViewController: UIViewControllerType,
        context: Context
    ) {
        guard let navigationController = uiViewController as? UINavigationController else {
            Logger.feed.error("ContactView should have been a UINavigationController")
            return
        }

        navigationController.setViewControllers([createViewController()], animated: false)
    }

    private func createViewController() -> UIViewController {
        let currentContacts = contacts.latest
        let viewController = CustomContactViewController(
            store: careStore,
            contacts: currentContacts,
            viewSynchronizer: OCKSimpleContactViewSynchronizer()
        )
        return viewController
    }

    static func query() -> OCKContactQuery {
        let query = OCKContactQuery(for: Date())
        return query
    }
}
#else
struct ContactView: View {
    var body: some View {
        NavigationView {
            ContentUnavailableView(
                "Contacts Unavailable",
                systemImage: "person.2.slash",
                description: Text("This contact interface is only available on iOS.")
            )
            .navigationTitle("Contacts")
        }
    }
}
#endif

struct ContactView_Previews: PreviewProvider {
    static var previews: some View {
        ContactView()
            .environment(\.careStore, Utility.createPreviewStore())
            .careKitStyle(Styler())
    }
}
