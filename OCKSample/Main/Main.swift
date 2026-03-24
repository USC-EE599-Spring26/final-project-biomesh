//
//  Main.swift
//  OCKSample
//
//  Created by Ray on 23/03/2026.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("Welcome to BioMesh")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Track your caffeine, sleep, and anxiety to improve your health.")
                .multilineTextAlignment(.center)
                .padding()

            Image(systemName: "heart.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)

            Spacer()

            Button("Get Started") {
                hasSeenOnboarding = true
            }
            .padding()
            .frame(width: 200)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)

            Spacer()
        }
        .padding()
    }
}
