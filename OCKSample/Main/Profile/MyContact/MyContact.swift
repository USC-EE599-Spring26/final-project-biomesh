//
//  MyContactView.swift
//  OCKSample
//
//  Created by Corey Baker on 4/2/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//


import SwiftUI
import CareKitStore

struct MyContactView: UIViewControllerRepresentable {
    @Environment(\.careStore) var careStore

    func makeUIViewController(context: Context) -> some UIViewController {
        UINavigationController(rootViewController: MyContactViewController(store: careStore))
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
