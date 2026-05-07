//
//  WatchProfileView.swift
//  OCKSample
//
//  Created by Alarik Damrow on 5/2/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

#if os(watchOS)

import SwiftUI

struct WatchProfileView: View {
    @ObservedObject var loginViewModel: LoginViewModel
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    ProfileImageView(viewModel: viewModel)

                    Text("BioMesh")
                        .font(.headline)

                    Text("Profile")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section {
                Button(role: .destructive) {
                    Task {
                        await loginViewModel.logout()
                    }
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Profile")
    }
}

#endif
