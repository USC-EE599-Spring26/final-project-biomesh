//
//  MyContactView.swift
//  OCKSample
//
//  Created by Corey Baker on 4/2/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import SwiftUI

struct MyContactView: View {
    @Environment(\.careStore) private var careStore

    @State private var myContacts = [OCKAnyContact]()
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Group {
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if myContacts.isEmpty {
                    ContentUnavailableView(
                        "No Contact Found",
                        systemImage: "person.crop.circle.badge.exclam",
                        description: Text("Your personal contact card has not been created yet.")
                    )
                } else {
                    List(myContacts, id: \.id) { contact in
                        NavigationLink {
                            MyContactDetailView(contact: contact)
                        } label: {
                            MyContactRow(contact: contact)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Contact")
        }
        .task {
            await loadMyContacts()
        }
    }

    private func loadMyContacts() async {
        do {
            guard let personUUIDString = try? await Utility.getRemoteClockUUID().uuidString else {
                myContacts = []
                errorMessage = "Could not determine the signed-in user."
                return
            }

            let results = try await careStore.fetchAnyContacts(query: Self.query())
            myContacts = results.filter { $0.id == personUUIDString }
            errorMessage = nil
        } catch {
            myContacts = []
            errorMessage = "Failed to load your contact: \(error.localizedDescription)"
        }
    }

    static func query() -> OCKContactQuery {
        OCKContactQuery(for: Date())
    }
}

private struct MyContactRow: View {
    let contact: OCKAnyContact

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(fullName)
                .font(.headline)

            if let title = contact.title, !title.isEmpty {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let role = contact.role, !role.isEmpty {
                Text(role)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
    }

    private var fullName: String {
        let given = contact.name.givenName ?? ""
        let family = contact.name.familyName ?? ""
        let name = "\(given) \(family)".trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Unnamed Contact" : name
    }
}

private struct MyContactDetailView: View {
    let contact: OCKAnyContact

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(fullName)
                    .font(.largeTitle)
                    .bold()

                if let title = contact.title, !title.isEmpty {
                    detailSection("Title", value: title)
                }

                if let role = contact.role, !role.isEmpty {
                    detailSection("Role", value: role)
                }

                if let phoneNumbers = contact.phoneNumbers, !phoneNumbers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone")
                            .font(.headline)

                        ForEach(Array(phoneNumbers.enumerated()), id: \.offset) { _, item in
                            if let url = phoneURL(item.value) {
                                Link(item.value, destination: url)
                            } else {
                                Text(item.value)
                            }
                        }
                    }
                }

                if let emails = contact.emailAddresses, !emails.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)

                        ForEach(Array(emails.enumerated()), id: \.offset) { _, item in
                            if let url = emailURL(item.value) {
                                Link(item.value, destination: url)
                            } else {
                                Text(item.value)
                            }
                        }
                    }
                }

                let addressText = formattedAddress(contact.address)
                if !addressText.isEmpty {
                    detailSection("Address", value: addressText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("My Contact")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var fullName: String {
        let given = contact.name.givenName ?? ""
        let family = contact.name.familyName ?? ""
        let name = "\(given) \(family)".trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Unnamed Contact" : name
    }

    @ViewBuilder
    private func detailSection(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(value)
                .foregroundColor(.secondary)
        }
    }

    private func formattedAddress(_ address: OCKPostalAddress?) -> String {
        guard let address else { return "" }

        return [
            address.street,
            address.city,
            address.state,
            address.postalCode,
            address.country
        ]
        .compactMap { component in
            component.isEmpty ? nil : component
        }
        .joined(separator: ", ")
    }

    private func phoneURL(_ value: String) -> URL? {
        let digits = value.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel://\(digits)")
    }

    private func emailURL(_ value: String) -> URL? {
        guard !value.isEmpty else { return nil }
        return URL(string: "mailto:\(value)")
    }
}

struct MyContactView_Previews: PreviewProvider {
    static var previews: some View {
        MyContactView()
            .environment(\.careStore, Utility.createPreviewStore())
    }
}
