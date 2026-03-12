//
//  CareKitCard.swift
//  OCKSample
//
//  Created by Alarik Damrow on 3/10/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

enum CareKitCard: String, Codable {
    case button
    case checklist
    case simple
    case instruction
    case labeledValue
    case numericProgress
    case grid
    case featured
    case link
    case survey
}
