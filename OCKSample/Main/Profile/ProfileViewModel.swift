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
    @Published var allergies: String = ""
    @Published var email: String = ""
    @Published var messagingNumber: String = ""
    @Published var phoneNumber: String = ""
    @Published var otherContactInfo: String = ""
    @Published var isShowingSaveAlert = false
    @Published var isPresentingAddTask = false
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
                    // Use `.set()` to update ParseObject's that have already been saved before.
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
    private(set) var alertMessage = "All changs saved successfully!"
    private var contact: OCKContact? // TODO: need to publish contact updates like patient

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

            if let currentAllergy = newValue?.allergies?.first {
                allergies = currentAllergy
            } else {
                allergies = ""
            }
        }
    }

    // MARK: Helpers (public)

    func updatePatient(_ patient: OCKAnyPatient) {
        guard let patient = patient as? OCKPatient,
              // Only update if we have a newer version.
              patient.uuid != self.patient?.uuid else {
            return
        }
        self.patient = patient

        // Fetch the profile picture if we have a patient.
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
              // Has to be my contact.
              contact.id == currentPatient.id,
              // Only update if we have a newer version.
              contact.uuid != self.contact?.uuid else {
            return
        }

        self.contact = contact

        street = contact.address?.street ?? ""
        city = contact.address?.city ?? ""
        state = contact.address?.state ?? ""
        zipcode = contact.address?.postalCode ?? ""
        country = contact.address?.country ?? ""

        email = contact.emailAddresses?.first?.value ?? ""
        messagingNumber = contact.messagingNumbers?.first?.value ?? ""
        phoneNumber = contact.phoneNumbers?.first?.value ?? ""
        otherContactInfo = contact.otherContactInfo?.first?.value ?? ""
    }

    @MainActor
    private func fetchProfilePicture() async throws {

         // Profile pics are stored in Parse User.
        guard let currentUser = (try? await User.current().fetch()) else {
            Logger.profile.error("User is not logged in")
            return
        }

        if let pictureFile = currentUser.profilePicture {

            // Download picture from server if needed
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
        alertMessage = "All changs saved successfully!"
        do {
            try await savePatient()
            try await saveContact()
        } catch {
            alertMessage = "Could not save profile: \(error)"
        }
        isShowingSaveAlert = true // Make alert pop up for user.
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

            let notes = [OCKNote(author: firstName,
                                 title: "New Note",
                                 content: note)]
            if patient?.notes != notes {
                patientHasBeenUpdated = true
                patientToUpdate.notes = notes
            }

            if patient?.allergies != [allergies] {
                patientHasBeenUpdated = true
                patientToUpdate.allergies = [allergies]
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
            newPatient.notes = [OCKNote(author: firstName,
                                        title: "New Note",
                                        content: note)]
            newPatient.allergies = [allergies]

            _ = try await AppDelegateKey.defaultValue?.store.addAnyPatient(newPatient)
            Logger.profile.info("Succesffully saved new patient")
        }
    }

    @MainActor
    func saveContact() async throws {

        if var contactToUpdate = contact {
            var contactHasBeenUpdated = false

            if let patientName = patient?.name,
               contact?.name != patient?.name {
                contactHasBeenUpdated = true
                contactToUpdate.name = patientName
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
            Logger.profile.info("Succesffully saved new contact")
        }
    }
    private var emailLabeledValues: [OCKLabeledValue] {
        email.isEmpty ? [] : [OCKLabeledValue(label: "email", value: email)]
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
    
    static func queryPatient() -> OCKPatientQuery {
        OCKPatientQuery(for: Date())
    }

    static func queryContacts() -> OCKContactQuery {
        OCKContactQuery(for: Date())
    }

}
