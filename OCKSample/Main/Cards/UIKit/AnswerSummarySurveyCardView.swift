//
//  AnswerSummarySurveyCardView.swift
//  OCKSample
//
//  Created by Alarik Damrow on 4/19/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitEssentials
import CareKitStore
import CareKitUI
import ResearchKitSwiftUI
import SwiftUI

struct AnswerSummarySurveyCardView: View {
    @Environment(\.isCardEnabled) private var isCardEnabled

    let event: OCKAnyEvent
    let task: OCKTask

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                surveyForm

                if !latestAnswers.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Latest Answers")
                            .font(.headline)

                        ForEach(Array(latestAnswers.enumerated()), id: \.offset) { index, item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.question)
                                    .font(.subheadline.weight(.semibold))

                                Text(item.answer)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if index < latestAnswers.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal, isCardEnabled ? 0 : 16)
                    .padding(.bottom, isCardEnabled ? 0 : 16)
                }
            }
            .padding(isCardEnabled ? [.all] : [])
        }
        .padding(.vertical)
    }

    @ViewBuilder
    private var surveyForm: some View {
        if let steps = task.surveySteps {
            ResearchSurveyView(event: event) {
                ResearchCareForm(event: event) {
                    ForEach(steps) { step in
                        ResearchFormStep(
                            title: nil,
                            subtitle: nil
                        ) {
                            ForEach(step.questions) { question in
                                question.view()
                            }
                        }
                    }
                }
            }
        } else {
            Text("Survey unavailable.")
                .foregroundStyle(.secondary)
        }
    }

    private var latestAnswers: [(question: String, answer: String)] {
        guard
            let steps = task.surveySteps,
            let values = event.outcome?.values,
            !values.isEmpty
        else {
            return []
        }

        let questionTitles = Dictionary(
            uniqueKeysWithValues: steps
                .flatMap(\.questions)
                .map { ($0.id, $0.title) }
        )

        return values.compactMap { value in
            guard let kind = value.kind else { return nil }

            let question = questionTitles[kind] ?? prettify(kind)
            let answer = formattedAnswer(for: value)

            guard !answer.isEmpty else { return nil }
            return (question, answer)
        }
    }

    private func formattedAnswer(for value: OCKOutcomeValue) -> String {
        if let stringValue = value.stringValue, !stringValue.isEmpty {
            return stringValue
        }
        if let boolValue = value.booleanValue {
            return boolValue ? "Yes" : "No"
        }
        if let intValue = value.integerValue {
            return "\(intValue)"
        }
        if let doubleValue = value.doubleValue {
            if abs(doubleValue.rounded() - doubleValue) < 0.001 {
                return "\(Int(doubleValue.rounded()))"
            }
            return String(format: "%.1f", doubleValue)
        }
        if let dateValue = value.dateValue {
            return dateValue.formatted(date: .abbreviated, time: .shortened)
        }
        return ""
    }

    private func prettify(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

#if !os(watchOS)
extension AnswerSummarySurveyCardView: EventViewable {
    public init?(
        event: OCKAnyEvent,
        store: any OCKAnyStoreProtocol
    ) {
        guard let task = event.task as? OCKTask else {
            return nil
        }
        self.init(event: event, task: task)
    }
}
#endif
