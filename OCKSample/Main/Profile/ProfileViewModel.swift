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
	@Published var street = ""
	@Published var city = ""
	@Published var state = ""
	@Published var zipcode = ""
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
		}
	}

	// MARK: Helpers (public)

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
		if let address = contact.address {
			street = address.street
			city = address.city
			state = address.state
			zipcode = address.postalCode
		}
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

			if patientHasBeenUpdated {
				_ = try await AppDelegateKey.defaultValue?.store.updateAnyPatient(patientToUpdate)
				Logger.profile.info("Successfully updated patient")
			}

		} else {
			guard let remoteUUID = (try? await Utility.getRemoteClockUUID())?.uuidString else {
				Logger.profile.error("The user currently is not logged in")
				return
			}

			var newPatient = OCKPatient(id: remoteUUID,
										givenName: firstName,
										familyName: lastName)
			newPatient.birthday = birthday

			_ = try await AppDelegateKey.defaultValue?.store.addAnyPatient(newPatient)
			Logger.profile.info("Successfully saved new patient")
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
                country: ""
			)
			if contact?.address != potentialAddress {
				contactHasBeenUpdated = true
				contactToUpdate.address = potentialAddress
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

			let newContact = OCKContact(
				id: remoteUUID,
				name: patientName,
				carePlanUUID: nil
			)

			_ = try await AppDelegateKey.defaultValue?.store.addAnyContact(newContact)
			Logger.profile.info("Successfully saved new contact")
		}
	}

	static func queryPatient() -> OCKPatientQuery {
		OCKPatientQuery(for: Date())
	}

	static func queryContacts() -> OCKContactQuery {
		OCKContactQuery(for: Date())
	}
}
