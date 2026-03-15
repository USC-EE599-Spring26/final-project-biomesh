//
//  CardEnabledEnvironmentKey.swift
//  OCKSample
//
//  Created by Alarik Damrow on 3/15/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI

private struct CardEnabledEnvironmentKey: EnvironmentKey {
    nonisolated(unsafe) static var defaultValue = true
}

extension EnvironmentValues {
    var isCardEnabled: Bool {
        get { self[CardEnabledEnvironmentKey.self] }
        set { self[CardEnabledEnvironmentKey.self] = newValue }
    }
}

extension View {
    func cardEnabled(_ enabled: Bool) -> some View {
        environment(\.isCardEnabled, enabled)
    }
}
