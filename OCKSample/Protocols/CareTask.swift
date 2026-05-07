//
//  CareTask.swift
//  OCKSample
//
//  Created by Corey Baker on 3/3/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

protocol CareTask {
    var id: String { get }
    var userInfo: [String: String]? { get set }

    /// The card type related to the task.
    var card: CareKitCard { get set }

    /// The priority level of a particular task.
    var priority: Int? { get set }
}

extension CareTask {
    /**
     Represents the CareKit that can be used for viewing this task.
     */
    var card: CareKitCard {
        get {
            guard let cardInfo = userInfo?[Constants.card],
                  let careKitCard = CareKitCard(rawValue: cardInfo) else {
                return .grid // Default card if none was saved
            }
            return careKitCard // Saved card type
        }
        set {
            if userInfo == nil {
                // Initialize userInfo with empty dictionary
                userInfo = .init()
            }
            // Set the new card type
            userInfo?[Constants.card] = newValue.rawValue
        }
    }

    var priority: Int? {
        get {
            guard let priorityInfo = userInfo?[Constants.priority] else {
                // Default to lower priority
                return 100
            }
            return Int(priorityInfo)
        }
        set {
            if userInfo == nil {
                // Initialize userInfo with empty dictionary
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

extension Sequence where Element == CareTask {
    func sortedByPriority() -> [Element] {
        sorted { $0.priority ?? 100 < $1.priority ?? 100 }
    }
}

