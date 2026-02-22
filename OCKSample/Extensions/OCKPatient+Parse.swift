//
//  OCKPatient+Parse.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore
import ParseSwift
extension OCKPatient {
    var remoteClockUUID: UUID? {
        get {
            guard let uuidString = remoteID,
                let uuid = UUID(uuidString: uuidString) else {
                return nil
            }
            return uuid
        }
        set {
            remoteID = newValue?.uuidString
        }
    }
    var userType: UserType? {
        get {
            guard let typeString = userInfo?[Constants.userTypeKey],
                let type = UserType(rawValue: typeString) else {
                return nil
            }
            return type
        }
        set {
            guard let type = newValue else {
                userInfo?.removeValue(forKey: Constants.userTypeKey)
                return
            }
            if userInfo != nil {
                userInfo?[Constants.userTypeKey] = type.rawValue
            } else {
                userInfo = [Constants.userTypeKey: type.rawValue]
            }
        }
    }
    init(remoteUUID: UUID, id: String, givenName: String, familyName: String) {
        self.init(id: id,
                  givenName: givenName,
                  familyName: familyName)
        remoteClockUUID = remoteUUID
    }
}
