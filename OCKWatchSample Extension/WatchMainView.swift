//
//  WatchMainView.swift
//  OCKSample
//
//  Created by Alarik Damrow on 5/2/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI

struct WatchMainView: View {
    var body: some View {
        TabView {
            WatchCareListView()
            WatchProfileLiteView()
        }
        .tabViewStyle(.page)
    }
}
