//
//  ProfileImageView.swift
//  OCKSample
//
//  Created by Corey Baker on 4/2/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
import SwiftUI

#if os(iOS)
import UIKit
#endif

struct ProfileImageView: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        Group {
            #if os(iOS)
            if let image = viewModel.profileUIImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                placeholder
            }
            #else
            placeholder
            #endif
        }
        .frame(width: 100, height: 100, alignment: .center)
        .clipShape(Circle())
        .shadow(radius: 10)
        .overlay(Circle().stroke(Color.accentColor, lineWidth: 5))
        #if os(iOS)
        .onTapGesture {
            viewModel.isPresentingImagePicker = true
        }
        #endif
    }

    private var placeholder: some View {
        Image(systemName: "person.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding(18)
            .foregroundStyle(.secondary)
    }
}

struct ProfileImageView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileImageView(viewModel: .init())
    }
}
