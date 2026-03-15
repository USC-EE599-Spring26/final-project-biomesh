//
//  CareKitCard.swift
//  OCKSample
//
//  Created by Alarik Damrow on 3/10/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

enum CareKitCard: String, CaseIterable, Identifiable {
    case button = "Button"
    case checklist = "Checklist"
    case instruction = "Instruction"
    case simple = "Simple"
    case numericProgress = "Numeric Progress"
    case labeledValue = "Labeled Value"
    case grid = "Grid"
    case survey = "Survey"
    case link = "Link"
    case featured = "Featured"
    case custom = "Custom"
    var id: String { rawValue }
}
