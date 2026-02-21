//
//  OCKStore.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//
import Foundation
import CareKitStore
extension OCKStore {
    func addContactsIfNotPresent(_ contacts: [OCKContact]) async throws -> [OCKContact] {
        let contactIdsToAdd = contacts.compactMap { $0.id }
        var query = OCKContactQuery(for: Date())
        query.ids = contactIdsToAdd
        let foundContacts = try await fetchContacts(query: query)
        let contactsNotInStore = contacts.filter { potentialContact in
            foundContacts.first(where: { $0.id == potentialContact.id }) == nil
        }
        guard !contactsNotInStore.isEmpty else { return [] }
        return try await addContacts(contactsNotInStore)
    }
}
