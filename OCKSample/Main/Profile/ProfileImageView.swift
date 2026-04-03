//
//  ProfileImageView.swift
//  OCKSample
//
//  Created by Corey Baker on 4/2/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI

struct ProfileImageView: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        Group {
            if let image = viewModel.profileUIImage {
                Image(uiImage: image)
                    .resizable()
            } else {
                Image(systemName: "person.fill")
                    .resizable()
            }
        }
        .aspectRatio(contentMode: .fit)
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .shadow(radius: 10)
        .overlay(Circle().stroke(Color.accentColor, lineWidth: 5))
        .onTapGesture {
            viewModel.isPresentingImagePicker = true
        }
    }
}
