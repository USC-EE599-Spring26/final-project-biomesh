//
//  UserType.swift
//  OCKSample
//
//  Created by Corey Baker on 4/14/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
enum UserType: String, Codable {
    case patient                           = "Patient"
    case none                              = "None"
    func allTypesAsArray() -> [String] {
        return [UserType.patient.rawValue,
                UserType.none.rawValue]
    }
}
