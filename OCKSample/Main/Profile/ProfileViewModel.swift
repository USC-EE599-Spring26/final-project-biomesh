//
//  Profile.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import CareKitEssentials
import ParseSwift
import SwiftUI
import os.log

@MainActor
class ProfileViewModel: ObservableObject {

    // MARK: Public read/write properties

    @Published var firstName = ""
    @Published var lastName = ""
    @Published var birthday = Date()
    @Published var sex: OCKBiologicalSex = .other("other")
    @Published var sexOtherField = "other"
    @Published var note = ""
    @Published var street = ""
    @Published var city = ""
    @Published var state = ""
    @Published var zipcode = ""
    @Published var country = ""
    @Published var allergies = ""
    @Published var emailAddress = ""
    @Published var messagingNumber = ""
    @Published var phoneNumber = ""
    @Published var otherContactInfo = ""
    @Published var isShowingSaveAlert = false
    @Published var isPresentingContact = false
    @Published var isPresentingImagePicker = false
    @Published var profileUIImage = UIImage(systemName: "person.fill") {
        willSet {
            guard self.profileUIImage != newValue,
                  let inputImage = newValue else {
                return
            }

            if !isSettingProfilePictureForFirstTime {
                Task {
                    guard var currentUser = (try? await User.current()),
                          let image = inputImage.jpegData(compressionQuality: 0.25) else {
                        Logger.profile.error("User is not logged in or could not compress image")
                        return
                    }

                    let newProfilePicture = ParseFile(name: "profile.jpg", data: image)
                    currentUser = currentUser.set(\.profilePicture, to: newProfilePicture)
                    do {
                        _ = try await currentUser.save()
                        Logger.profile.info("Saved updated profile picture successfully.")
                    } catch {
                        Logger.profile.error("Could not save profile picture: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    @Published private(set) var error: Error?
    private(set) var alertMessage = "All changes saved successfully!"
    private var contact: OCKContact?

    // MARK: Private read/write properties

    private var isSettingProfilePictureForFirstTime = true

    var patient: OCKPatient? {
        willSet {
            if let currentFirstName = newValue?.name.givenName {
                firstName = currentFirstName
            } else {
                firstName = ""
            }

            if let currentLastName = newValue?.name.familyName {
                lastName = currentLastName
            } else {
                lastName = ""
            }

            if let currentBirthday = newValue?.birthday {
                birthday = currentBirthday
            } else {
                birthday = Date()
            }

            if let currentSex = newValue?.sex {
                sex = currentSex
                if case let .other(otherValue) = currentSex {
                    sexOtherField = otherValue
                } else {
                    sexOtherField = "other"
                }
            } else {
                sex = .other("other")
                sexOtherField = "other"
            }

            if let currentNote = newValue?.notes?.first?.content {
                note = currentNote
            } else {
                note = ""
            }

            if let currentAllergies = newValue?.allergies,
               !currentAllergies.isEmpty {
                allergies = currentAllergies.joined(separator: ", ")
            } else {
                allergies = ""
            }
        }
    }

    // MARK: Helpers

    func updatePatient(_ patient: OCKAnyPatient) {
        guard let patient = patient as? OCKPatient,
              patient.uuid != self.patient?.uuid else {
            return
        }
        self.patient = patient

        Task {
            do {
                try await fetchProfilePicture()
            } catch {
                Logger.profile.error("Failed to fetch profile picture: \(error.localizedDescription)")
            }
        }
    }

    func updateContact(_ contact: OCKAnyContact) {
        guard let currentPatient = self.patient,
              let contact = contact as? OCKContact,
              contact.id == currentPatient.id,
              contact.uuid != self.contact?.uuid else {
            return
        }

        self.contact = contact

        street = contact.address?.street ?? ""
        city = contact.address?.city ?? ""
        state = contact.address?.state ?? ""
        zipcode = contact.address?.postalCode ?? ""
        country = contact.address?.country ?? ""

        emailAddress = contact.emailAddresses?.first?.value ?? ""
        messagingNumber = contact.messagingNumbers?.first?.value ?? ""
        phoneNumber = contact.phoneNumbers?.first?.value ?? ""
        otherContactInfo = contact.otherContactInfo?.first?.value ?? ""
    }

    @MainActor
    private func fetchProfilePicture() async throws {
        guard let currentUser = (try? await User.current().fetch()) else {
            Logger.profile.error("User is not logged in")
            return
        }

        if let pictureFile = currentUser.profilePicture {
            do {
                let profilePicture = try await pictureFile.fetch()
                guard let path = profilePicture.localURL?.relativePath else {
                    Logger.profile.error("Could not find relative path for profile picture.")
                    return
                }
                self.profileUIImage = UIImage(contentsOfFile: path)
            } catch {
                Logger.profile.error("Could not fetch profile picture: \(error.localizedDescription).")
            }
        }
        self.isSettingProfilePictureForFirstTime = false
    }

    // MARK: User intentional behavior

    @MainActor
    func saveProfile() async {
        alertMessage = "All changes saved successfully!"
        do {
            try await savePatient()
            try await saveContact()
        } catch {
            alertMessage = "Could not save profile: \(error)"
        }
        isShowingSaveAlert = true
    }

    @MainActor
    func savePatient() async throws {
        if var patientToUpdate = patient {
            var patientHasBeenUpdated = false

            if patient?.name.givenName != firstName {
                patientHasBeenUpdated = true
                patientToUpdate.name.givenName = firstName
            }

            if patient?.name.familyName != lastName {
                patientHasBeenUpdated = true
                patientToUpdate.name.familyName = lastName
            }

            if patient?.birthday != birthday {
                patientHasBeenUpdated = true
                patientToUpdate.birthday = birthday
            }

            if patient?.sex != sex {
                patientHasBeenUpdated = true
                patientToUpdate.sex = sex
            }

            let notes = [OCKNote(author: firstName, title: "New Note", content: note)]
            if patient?.notes != notes {
                patientHasBeenUpdated = true
                patientToUpdate.notes = notes
            }

            if patient?.allergies != parsedAllergies {
                patientHasBeenUpdated = true
                patientToUpdate.allergies = parsedAllergies
            }

            if patientHasBeenUpdated {
                _ = try await AppDelegateKey.defaultValue?.store.updateAnyPatient(patientToUpdate)
                Logger.profile.info("Successfully updated patient")
            }
        } else {
            guard let remoteUUID = (try? await Utility.getRemoteClockUUID())?.uuidString else {
                Logger.profile.error("The user currently is not logged in")
                return
            }

            var newPatient = OCKPatient(
                id: remoteUUID,
                givenName: firstName,
                familyName: lastName
            )
            newPatient.birthday = birthday
            newPatient.sex = sex
            newPatient.notes = [OCKNote(author: firstName, title: "New Note", content: note)]
            newPatient.allergies = parsedAllergies

            _ = try await AppDelegateKey.defaultValue?.store.addAnyPatient(newPatient)
            Logger.profile.info("Successfully saved new patient")
        }
    }

    @MainActor
    func saveContact() async throws {
        if var contactToUpdate = contact {
            var contactHasBeenUpdated = false

            if let patientName = patient?.name,
               contact?.name != patientName {
                contactHasBeenUpdated = true
                contactToUpdate.name = patientName
            }

            let currentTitle = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            if contactToUpdate.title != currentTitle {
                contactHasBeenUpdated = true
                contactToUpdate.title = currentTitle
            }

            if contactToUpdate.role != "Patient" {
                contactHasBeenUpdated = true
                contactToUpdate.role = "Patient"
            }

            let potentialAddress = OCKPostalAddress(
                street: street,
                city: city,
                state: state,
                postalCode: zipcode,
                country: country
            )
            if contact?.address != potentialAddress {
                contactHasBeenUpdated = true
                contactToUpdate.address = potentialAddress
            }

            if contact?.emailAddresses != emailLabeledValues {
                contactHasBeenUpdated = true
                contactToUpdate.emailAddresses = emailLabeledValues
            }

            if contact?.messagingNumbers != messagingLabeledValues {
                contactHasBeenUpdated = true
                contactToUpdate.messagingNumbers = messagingLabeledValues
            }

            if contact?.phoneNumbers != phoneLabeledValues {
                contactHasBeenUpdated = true
                contactToUpdate.phoneNumbers = phoneLabeledValues
            }

            if contact?.otherContactInfo != otherContactInfoLabeledValues {
                contactHasBeenUpdated = true
                contactToUpdate.otherContactInfo = otherContactInfoLabeledValues
            }

            if contactHasBeenUpdated {
                _ = try await AppDelegateKey.defaultValue?.store.updateAnyContact(contactToUpdate)
                Logger.profile.info("Successfully updated contact")
            }
        } else {
            guard let remoteUUID = (try? await Utility.getRemoteClockUUID())?.uuidString else {
                Logger.profile.error("The user currently is not logged in")
                return
            }

            guard let patientName = self.patient?.name else {
                Logger.profile.info("The patient did not have a name.")
                return
            }

            var newContact = OCKContact(
                id: remoteUUID,
                name: patientName,
                carePlanUUID: nil
            )
            newContact.title = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            newContact.role = "Patient"
            newContact.address = OCKPostalAddress(
                street: street,
                city: city,
                state: state,
                postalCode: zipcode,
                country: country
            )
            newContact.emailAddresses = emailLabeledValues
            newContact.messagingNumbers = messagingLabeledValues
            newContact.phoneNumbers = phoneLabeledValues
            newContact.otherContactInfo = otherContactInfoLabeledValues

            _ = try await AppDelegateKey.defaultValue?.store.addAnyContact(newContact)
            Logger.profile.info("Successfully saved new contact")
        }
    }

    private var emailLabeledValues: [OCKLabeledValue] {
        emailAddress.isEmpty ? [] : [OCKLabeledValue(label: "email", value: emailAddress)]
    }

    private var messagingLabeledValues: [OCKLabeledValue] {
        messagingNumber.isEmpty ? [] : [OCKLabeledValue(label: "messaging", value: messagingNumber)]
    }

    private var phoneLabeledValues: [OCKLabeledValue] {
        phoneNumber.isEmpty ? [] : [OCKLabeledValue(label: "phone", value: phoneNumber)]
    }

    private var otherContactInfoLabeledValues: [OCKLabeledValue] {
        otherContactInfo.isEmpty ? [] : [OCKLabeledValue(label: "other", value: otherContactInfo)]
    }

    private var parsedAllergies: [String] {
        allergies
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func queryPatient() -> OCKPatientQuery {
        OCKPatientQuery(for: Date())
    }

    static func queryContacts() -> OCKContactQuery {
        OCKContactQuery(for: Date())
    }
}
