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

struct ContactView: UIViewControllerRepresentable {
    @Environment(\.careStore) var careStore
    @CareStoreFetchRequest(query: query()) private var contacts

    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = createViewController()
        let navigationController = UINavigationController(
                    rootViewController: viewController
                )
                return navigationController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType,
                                context: Context) {
        guard let navigationController = uiViewController as? UINavigationController else {
            Logger.feed.error("ContactView should have been a UINavigationController")
            return
        }
        navigationController.setViewControllers([createViewController()], animated: false)
    }

    func createViewController() -> UIViewController {
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
            // BAKER: Appears to be a bug in CareKit, commenting these out for now
            /*query.sortDescriptors.append(
                .familyName(ascending: true)
            )
            query.sortDescriptors.append(
                .givenName(ascending: true)
            ) */
            return query
        }
}

struct ContactView_Previews: PreviewProvider {

    static var previews: some View {
        ContactView()
            .environment(\.careStore, Utility.createPreviewStore())
			.careKitStyle(Styler())
    }
}
