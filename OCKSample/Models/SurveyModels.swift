//
//  SurveyModels.swift
//  OCKSample
//
//  Created by Alarik Damrow on 3/11/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI

struct TextChoice: Identifiable, Codable, Hashable {
    let id: String
    let choiceText: String
    let value: String
}

enum SurveyQuestionType: String, Codable, Hashable {
    case multipleChoice
    case slider
}

enum ChoiceSelectionLimit: String, Codable, Hashable {
    case single
}

struct SurveyQuestion: Identifiable, Codable, Hashable {
    let id: String
    let type: SurveyQuestionType
    let required: Bool
    let title: String
    var detail: String?
    var textChoices: [TextChoice]?
    var choicesSelectionLimit: ChoiceSelectionLimit?
    var integerRange: ClosedRange<Int>?
    var sliderStepValue: Int?
}

struct SurveyStep: Identifiable, Codable, Hashable {
    let id: String
    let questions: [SurveyQuestion]
}

struct SurveyQuestionView: View {
    let question: SurveyQuestion

    @State private var selectedChoiceID: String?
    @State private var sliderValue: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.title)
                .font(.headline)

            if let detail = question.detail, !detail.isEmpty {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            switch question.type {
            case .multipleChoice:
                multipleChoiceView

            case .slider:
                sliderQuestionView
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundFillColor)
        )
    }

    private var backgroundFillColor: Color {
        #if os(watchOS)
        return Color.gray.opacity(0.2)
        #else
        return Color(.secondarySystemBackground)
        #endif
    }

    @ViewBuilder
    private var multipleChoiceView: some View {
        if let choices = question.textChoices, !choices.isEmpty {
            VStack(spacing: 10) {
                ForEach(choices) { choice in
                    Button {
                        selectedChoiceID = choice.id
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: selectedChoiceID == choice.id
                                  ? "largecircle.fill.circle"
                                  : "circle")
                            Text(choice.choiceText)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            Text("No choices available")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var sliderQuestionView: some View {
        let range = question.integerRange ?? 0...10
        let step = Double(question.sliderStepValue ?? 1)

        VStack(alignment: .leading, spacing: 8) {
            Slider(
                value: $sliderValue,
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: step
            )

            Text("Selected: \(Int(sliderValue))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            if sliderValue == 0 {
                sliderValue = Double(range.lowerBound)
            }
        }
    }
}
