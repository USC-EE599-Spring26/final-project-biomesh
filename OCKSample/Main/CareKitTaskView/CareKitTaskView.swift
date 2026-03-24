//
//  CareKitTaskView.swift
//  OCKSample
//
//  Created by Corey Baker on 2/26/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI

struct CareKitTaskView: View {

    // MARK: Navigation
    @State var isShowingAlert = false
    @State var isAddingTask = false

    // MARK: View
    @StateObject var viewModel = CareKitTaskViewModel()
    @State var title = ""
    @State var instructions = ""
    @State var selectedCard: CareKitCard = .button

    var body: some View {

        NavigationView {
            Form {
                TextField("Title",
                          text: $title)
                TextField("Instructions",
                          text: $instructions)
                Picker("Card View", selection: $selectedCard) {
                    ForEach(CareKitCard.allCases) { item in
                        Text(item.rawValue)
                    }
                }
                Section("Task") {
                    Button("Add") {
                        addTask {
                            await viewModel.addTask(
                                title,
                                instructions: instructions,
                                cardType: selectedCard
                            )
                        }
                    }.alert(
                        "Task has been added",
                        isPresented: $isShowingAlert
                    ) {
                        Button("OK") {
                            isShowingAlert = false
                        }
                    }.disabled(isAddingTask)
                }
                Section("HealthKitTask") {
                    Button("Add") {
                        addTask {
                            await viewModel.addHealthKitTask(
                                title,
                                instructions: instructions,
                                cardType: selectedCard
                            )
                        }
                    }.alert(
                        "HealthKitTask has been added",
                        isPresented: $isShowingAlert
                    ) {
                        Button("OK") {
                            isShowingAlert = false
                        }
                    }.disabled(isAddingTask)
                }
            }
        }
    }

    // MARK: Helpers
    func addTask(_ task: @escaping (() async -> Void)) {
        isAddingTask = true
        Task {
            await task()
            isAddingTask = false
            isShowingAlert = true
        }
    }

}

#Preview {
    CareKitTaskView()
}

