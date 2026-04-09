//
//  CustomContactViewController.swift
//  OCKSample
//
//  Created by Ray on 07/04/2026.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import UIKit
import CareKitStore
import CareKit
import Contacts
import ContactsUI
import ParseSwift
import ParseCareKit
import os.log

class CustomContactViewController: OCKListViewController, @unchecked Sendable {

    fileprivate var allContacts = [OCKContact]()
    var contacts: [CareStoreFetchedResult<OCKAnyContact>]? {
        didSet {
            reloadView()
        }
    }

    /// The store the view controller uses for synchronization.
    fileprivate let store: OCKAnyStoreProtocol
    fileprivate let viewSynchronizer: OCKSimpleContactViewSynchronizer

    /// Create an instance of the view controller. Will hook up the calendar to the tasks collection,
    /// and query and display the tasks.
    ///
    /// - Parameter store: The store from which to query the tasks.
    /// - Parameter contacts: The current contacts queryied.
    /// - Parameter viewSynchronizer: The type of view to show
    init(
        store: OCKAnyStoreProtocol,
        contacts: [CareStoreFetchedResult<OCKAnyContact>]? = nil,
        viewSynchronizer: OCKSimpleContactViewSynchronizer
    ) {
        self.store = store
        self.contacts = contacts
        self.viewSynchronizer = viewSynchronizer
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.searchBarStyle = UISearchBar.Style.prominent
        searchController.searchBar.placeholder = " Search Contacts"
        searchController.searchBar.showsCancelButton = true
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        definesPresentationContext = true

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                           target: self,
                                                           action: #selector(presentContactsListViewController))

        reloadView()
    }

    override func viewDidAppear(_ animated: Bool) {
        reloadView()
    }

    @objc private func presentContactsListViewController() {

        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        contactPicker.predicateForEnablingContact = NSPredicate(
          format: "phoneNumbers.@count > 0")
        present(contactPicker, animated: true, completion: nil)
    }

    @objc private func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }

    func clearAndKeepSearchBar() {
        clear()
    }

    func reloadView() {
        Task {
            try? await updateContacts()
        }
    }

    @MainActor
    func updateContacts() async throws {

        guard (try? await User.current()) != nil else {
            Logger.contact.error("User not logged in")
            return
        }

        guard let personUUIDString = (try? await Utility.getRemoteClockUUID())?.uuidString else {
            Logger.contact.error("Could not get logged in personUUID")
            return
        }

        guard let contacts = contacts else {
            Logger.contact.error("No contacts to display")
            return
        }

        // TODO: Modify this filter to not show the contact info for this user
        let myID = try? await Utility.getRemoteClockUUID().uuidString

        let filterdContacts = contacts.filter { convertedContact in
            Logger.contact.info("Contact filtered: \(convertedContact.id)")

            if let myID = myID, convertedContact.id == myID {
                return false
            }

            return true
        }
        self.clearAndKeepSearchBar()
        // Map all filtered contacts to a direct contact.
        self.allContacts = filterdContacts.compactMap { $0.result as? OCKContact }
        self.displayContacts(self.allContacts)
    }

    @MainActor
    func displayContacts(_ contacts: [OCKAnyContact]) {

        for contact in contacts {
            var query = OCKContactQuery(for: Date())
            query.ids = [contact.id]
            query.limit = 1
            let contactViewController = OCKSimpleContactViewController(
                query: query,
                store: store,
                viewSynchronizer: viewSynchronizer
            )
            self.appendViewController(contactViewController, animated: false)
        }
    }

    func convertDeviceContacts(_ contact: CNContact) -> OCKAnyContact {

        var convertedContact = OCKContact(id: contact.identifier, givenName: contact.givenName,
                                          familyName: contact.familyName, carePlanUUID: nil)
        convertedContact.title = contact.jobTitle

        var emails = [OCKLabeledValue]()
        contact.emailAddresses.forEach {
            emails.append(OCKLabeledValue(label: $0.label ?? "email", value: $0.value as String))
        }
        convertedContact.emailAddresses = emails

        var phoneNumbers = [OCKLabeledValue]()
        contact.phoneNumbers.forEach {
            phoneNumbers.append(OCKLabeledValue(label: $0.label ?? "phone", value: $0.value.stringValue))
        }
        convertedContact.phoneNumbers = phoneNumbers
        convertedContact.messagingNumbers = phoneNumbers

        if let address = contact.postalAddresses.first {
            convertedContact.address = OCKPostalAddress(
                street: address.value.street,
                city: address.value.city,
                state: address.value.state,
                postalCode: address.value.postalCode,
                country: address.value.country
            )
        }

        return convertedContact
    }
}

extension CustomContactViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        Logger.contact.debug("Searching text is '\(searchText)'")

        if searchBar.text!.isEmpty {
            // Show all contacts
            clearAndKeepSearchBar()
            displayContacts(allContacts)
            return
        }

        clearAndKeepSearchBar()

        let filteredContacts = allContacts.filter { (contact: OCKAnyContact) -> Bool in

            if let givenName = contact.name.givenName {
                return givenName.lowercased().contains(searchText.lowercased())
            } else if let familyName = contact.name.familyName {
                return familyName.lowercased().contains(searchText.lowercased())
            } else {
                return false
            }
        }
        displayContacts(filteredContacts)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        clearAndKeepSearchBar()
        displayContacts(allContacts)
    }
}

extension CustomContactViewController: @MainActor CNContactPickerDelegate {

    func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelect contact: CNContact
    ) {
        let contactToAdd = convertDeviceContacts(contact)
        let allContacts = self.allContacts

        Task {
            guard (try? await User.current()) != nil else {
                Logger.contact.error("User not logged in")
                return
            }

            if !(allContacts.contains { $0.id == contactToAdd.id }) {

                // Note - once the functionality is added to edit a contact,
                // let the user potentially edit before the save
                do {
                    _ = try await store.addAnyContact(contactToAdd)
                } catch {
                    Logger.contact.error("Could not add contact: \(error.localizedDescription)")
                }
            }
        }
    }

    func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelect contacts: [CNContact]
    ) {
        let newContacts = contacts.compactMap {
            convertDeviceContacts($0)
        }
        let allContacts = self.allContacts

        Task {
            guard (try? await User.current()) != nil else {
                Logger.contact.error("User not logged in")
                return
            }

            var contactsToAdd = [OCKAnyContact]()
            for newContact in newContacts {
                // swiftlint:disable:next for_where
                if allContacts.first(where: { $0.id == newContact.id }) == nil {
                    contactsToAdd.append(newContact)
                }
            }

            let immutableContactsToAdd = contactsToAdd

            do {
                _ = try await store.addAnyContacts(immutableContactsToAdd)
            } catch {
                Logger.contact.error("Could not add contacts: \(error.localizedDescription)")
            }
        }
    }
}
