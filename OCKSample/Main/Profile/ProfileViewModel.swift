//
//  ProfileViewModel.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitEssentials
import CareKitStore
import ParseSwift
import SwiftUI
import os.log

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var firstName = ""
    @Published var lastName = ""
    @Published var birthday = Date()

    @Published var street = ""
    @Published var city = ""
    @Published var state = ""
    @Published var zipcode = ""
    @Published var country = ""

    @Published var isShowingSaveAlert = false
    @Published var isPresentingAddTask = false
    @Published var isPresentingContact = false
    @Published var isPresentingImagePicker = false

    @Published var profileUIImage: UIImage? = UIImage(systemName: "person.fill")
    @Published private(set) var error: Error?

    private(set) var alertMessage = "All changes saved successfully."

    private var isSettingProfilePictureForFirstTime = true
    private(set) var patient: OCKPatient?
    private(set) var contact: OCKContact?

    func updatePatient(_ patient: OCKAnyPatient) {
        guard let patient = patient as? OCKPatient,
              patient.uuid != self.patient?.uuid else {
            return
        }

        self.patient = patient
        firstName = patient.name.givenName ?? ""
        lastName = patient.name.familyName ?? ""
        birthday = patient.birthday ?? Date()

        Task {
            try? await fetchProfilePicture()
        }
    }

    func updateContact(_ contact: OCKAnyContact) {
        guard let currentPatient = patient,
              let contact = contact as? OCKContact,
              contact.id == currentPatient.id,
              contact.uuid != self.contact?.uuid else {
            return
        }

        self.contact = contact

        if let address = contact.address {
            street = address.street ?? ""
            city = address.city ?? ""
            state = address.state ?? ""
            zipcode = address.postalCode ?? ""
            country = address.country ?? ""
        } else {
            street = ""
            city = ""
            state = ""
            zipcode = ""
            country = ""
        }
    }

    private func fetchProfilePicture() async throws {
        guard let currentUser = try? await User.current().fetch() else {
            Logger.profile.error("User is not logged in")
            return
        }

        if let pictureFile = currentUser.profilePicture {
            do {
                let fetchedFile = try await pictureFile.fetch()
                guard let path = fetchedFile.localURL?.relativePath else {
                    Logger.profile.error("Could not find local path for profile picture.")
                    return
                }
                profileUIImage = UIImage(contentsOfFile: path)
            } catch {
                Logger.profile.error("Could not fetch profile picture: \(error.localizedDescription)")
            }
        }

        isSettingProfilePictureForFirstTime = false
    }

    func saveProfile() async {
        alertMessage = "All changes saved successfully."

        do {
            try await savePatient()
            try await saveContact()
            try await saveProfilePictureIfNeeded()
        } catch {
            alertMessage = "Could not save profile: \(error.localizedDescription)"
            self.error = error
        }

        isShowingSaveAlert = true
    }

    private func savePatient() async throws {
        if var patientToUpdate = patient {
            var changed = false

            if patientToUpdate.name.givenName != firstName {
                patientToUpdate.name.givenName = firstName
                changed = true
            }

            if patientToUpdate.name.familyName != lastName {
                patientToUpdate.name.familyName = lastName
                changed = true
            }

            if patientToUpdate.birthday != birthday {
                patientToUpdate.birthday = birthday
                changed = true
            }

            if changed {
                _ = try await AppDelegateKey.defaultValue?.store.updateAnyPatient(patientToUpdate)
                patient = patientToUpdate
                Logger.profile.info("Successfully updated patient")
            }
        } else {
            guard let remoteUUID = try? await Utility.getRemoteClockUUID().uuidString else {
                Logger.profile.error("The user is not logged in")
                return
            }

            var newPatient = OCKPatient(
                id: remoteUUID,
                givenName: firstName,
                familyName: lastName
            )
            newPatient.birthday = birthday

            _ = try await AppDelegateKey.defaultValue?.store.addAnyPatient(newPatient)
            patient = newPatient
            Logger.profile.info("Successfully saved new patient")
        }
    }

    private func saveContact() async throws {
        let address = OCKPostalAddress(
            street: street,
            city: city,
            state: state,
            postalCode: zipcode,
            country: country
        )

        if var contactToUpdate = contact {
            var changed = false

            if let patientName = patient?.name, contactToUpdate.name != patientName {
                contactToUpdate.name = patientName
                changed = true
            }

            if contactToUpdate.address != address {
                contactToUpdate.address = address
                changed = true
            }

            if changed {
                _ = try await AppDelegateKey.defaultValue?.store.updateAnyContact(contactToUpdate)
                contact = contactToUpdate
                Logger.profile.info("Successfully updated contact")
            }
        } else {
            guard let remoteUUID = try? await Utility.getRemoteClockUUID().uuidString else {
                Logger.profile.error("The user is not logged in")
                return
            }

            let givenName = patient?.name.givenName ?? firstName
            let familyName = patient?.name.familyName ?? lastName

            var newContact = OCKContact(
                id: remoteUUID,
                givenName: givenName,
                familyName: familyName,
                carePlanUUID: nil
            )
            newContact.address = address

            _ = try await AppDelegateKey.defaultValue?.store.addAnyContact(newContact)
            contact = newContact
            Logger.profile.info("Successfully saved new contact")
        }
    }

    private func saveProfilePictureIfNeeded() async throws {
        guard !isSettingProfilePictureForFirstTime,
              let inputImage = profileUIImage,
              var currentUser = try? await User.current(),
              let imageData = inputImage.jpegData(compressionQuality: 0.25) else {
            return
        }

        let newProfilePicture = ParseFile(name: "profile.jpg", data: imageData)
        currentUser.profilePicture = newProfilePicture

        do {
            _ = try await currentUser.save()
            Logger.profile.info("Saved updated profile picture successfully.")
        } catch {
            Logger.profile.error("Could not save profile picture: \(error.localizedDescription)")
            throw error
        }
    }

    static func queryPatient() -> OCKPatientQuery {
        OCKPatientQuery(for: Date())
    }

    static func queryContacts() -> OCKContactQuery {
        OCKContactQuery(for: Date())
    }
}
