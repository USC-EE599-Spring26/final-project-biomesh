//
//  PCKUtility.swift
//  OCKSample
//
//  Created by Corey Baker on 1/22/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import ParseCareKit
import ParseSwift
extension PCKUtility {
    static func isServerAvailable() async throws -> Bool {
        try await ParseServer.health() == .ok
    }
}
