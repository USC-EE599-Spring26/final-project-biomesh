//
//  MyContactViewController.swift
//  OCKSample
//
//  Created by Corey Baker on 4/2/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import UIKit
import CareKitStore
import CareKitUI
import CareKit
import Contacts
import ContactsUI
import ParseSwift
import ParseCareKit
import os.log

class MyContactViewController: OCKListViewController {

	fileprivate var contacts = [OCKAnyContact]()
	fileprivate let store: OCKAnyStoreProtocol
	fileprivate let viewSynchronizer = OCKDetailedContactViewSynchronizer()

	/// Initialize using a store manager. All of the contacts in the store manager will be queried and displayed.
	///
	/// - Parameter store: The store from which to query the tasks.
	init(store: OCKAnyStoreProtocol) {
		self.store = store
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		title = "My Contact Card"
		Task {
			try? await fetchMyContact()
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		Task {
			try? await fetchMyContact()
		}
	}

	override func appendViewController(
		_ viewController: UIViewController,
		animated: Bool
	) {
		super.appendViewController(viewController, animated: animated)
		if let carekitView = viewController.view as? OCKView {
			carekitView.customStyle = CustomStylerKey.defaultValue
		}
	}

	func fetchMyContact() async throws {

		guard (try? await User.current()) != nil,
			  let personUUIDString = try? await Utility.getRemoteClockUUID().uuidString else {
			Logger.myContact.error("User not logged in")
			self.contacts.removeAll()
			return
		}

		var query = OCKContactQuery(for: Date())
		query.ids = [personUUIDString]
		query.sortDescriptors.append(.familyName(ascending: true))
		query.sortDescriptors.append(.givenName(ascending: true))

		self.contacts = try await store.fetchAnyContacts(query: query)
		self.displayContacts()
	}

	func displayContacts() {
		self.clear()
		for contact in self.contacts {
			var contactQuery = OCKContactQuery(for: Date())
			contactQuery.ids = [contact.id]
			contactQuery.limit = 1
			let contactViewController = OCKDetailedContactViewController(
				query: contactQuery,
				store: store,
				viewSynchronizer: viewSynchronizer
			)
			self.appendViewController(contactViewController, animated: false)
		}
	}
}
