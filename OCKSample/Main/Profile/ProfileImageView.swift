//
//  ProfileImageView.swift
//  OCKSample
//
//  Created by Ray on 07/04/2026.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI

struct ProfileImageView: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        if let image = viewModel.profileUIImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100, alignment: .center)
                .clipShape(Circle())
                .shadow(radius: 10)
                .overlay(Circle().stroke(Color.accentColor, lineWidth: 5))
                .onTapGesture {
                    self.viewModel.isPresentingImagePicker = true
                }
        } else {
            Image(systemName: "person.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100, alignment: .center)
                .clipShape(Circle())
                .shadow(radius: 10)
                .overlay(Circle().stroke(Color.accentColor, lineWidth: 5))
                .onTapGesture {
                    self.viewModel.isPresentingImagePicker = true
                }
        }
    }
}

struct ProfileImageView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileImageView(viewModel: .init())
    }
}
