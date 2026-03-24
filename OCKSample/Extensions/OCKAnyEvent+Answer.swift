//
//  OCKAnyEvent+Answer.swift
//  OCKSample
//
//  Created by Faye on 3/23/26.
//

import CareKitStore

extension OCKAnyEvent {

    /// Returns the first `Double` outcome value whose `kind` matches the given string.
    func answer(kind: String) -> Double {
        let values = outcome?.values ?? []
        let match = values.first(where: { $0.kind == kind })
        return match?.doubleValue ?? 0
    }
}
