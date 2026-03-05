//
//  CareTask.swift
//  OCKSample
//
//  Created by Alarik Damrow on 3/10/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore

protocol CareTask {
    var id: String { get }
    var userInfo: [String: String]? { get set }

    var card: CareKitCard { get set }
    var priority: Int? { get set }
}

extension CareTask {

    var card: CareKitCard {
        get {
            guard let cardInfo = userInfo?[Constants.card],
                  let careKitCard = CareKitCard(rawValue: cardInfo) else {
                return .grid
            }
            return careKitCard
        }
        set {
            if userInfo == nil {
                userInfo = .init()
            }
            userInfo?[Constants.card] = newValue.rawValue
        }
    }

    var priority: Int? {
        get {
            guard let priorityInfo = userInfo?[Constants.priority] else {
                return 100
            }
            return Int(priorityInfo)
        }
        set {
            if userInfo == nil {
                userInfo = .init()
            }
            guard let newValue else {
                userInfo?[Constants.priority] = nil
                return
            }
            userInfo?[Constants.priority] = String(newValue)
        }
    }
}

extension Sequence where Element: CareTask {
    func sortedByPriority() -> [Element] {
        sorted { ($0.priority ?? 100) < ($1.priority ?? 100) }
    }
}
