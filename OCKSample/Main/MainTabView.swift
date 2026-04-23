//
//  MainTabView.swift
//  OCKSample
//
//  Created by Corey Baker on 9/18/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//
// swiftlint:disable:next line_length
// This was built using tutorial: https://www.hackingwithswift.com/books/ios-swiftui/creating-tabs-with-tabview-and-tabitem

import CareKitStore
import CareKitUI
import SwiftUI

struct MainTabView: View {
    @ObservedObject var loginViewModel: LoginViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CareView()
                .tabItem {
                    if selectedTab == 0 {
                        Image(systemName: "chart.line.text.clipboard")
                            .renderingMode(.template)
                    } else {
						Image(systemName: "chart.line.text.clipboard.fill")
                            .renderingMode(.template)
                    }
                }
                .tag(0)

			InsightsView()
				.tabItem {
					if selectedTab == 1 {
						Image(systemName: "chart.pie.fill")
							.renderingMode(.template)
					} else {
						Image(systemName: "chart.pie")
							.renderingMode(.template)
					}
				}
				.tag(1)

			ContactView()
				.tabItem {
					if selectedTab == 2 {
						Image(systemName: "phone.bubble.fill")
							.renderingMode(.template)
					} else {
						Image(systemName: "phone.bubble")
							.renderingMode(.template)
					}
				}
				.tag(2)

			ProfileView(loginViewModel: loginViewModel)
				.tabItem {
					if selectedTab == 3 {
						Image(systemName: "person.circle.fill")
							.renderingMode(.template)
					} else {
						Image(systemName: "person.circle")
							.renderingMode(.template)
					}
				}
				.tag(3)

            BioMeshAssistantView()
                .tabItem {
                    if selectedTab == 4 {
                        Image(systemName: "sparkles")
                            .renderingMode(.template)
                    } else {
                        Image(systemName: "sparkle.magnifyingglass")
                            .renderingMode(.template)
                    }
                }
                .tag(4)
        }
    }
}

private struct BioMeshAssistantView: View {
    @State private var messages = AssistantMessage.starterMessages
    @State private var draft = ""
    @State private var isWaitingForReply = false

    private let quickPrompts = [
        "I had too much caffeine",
        "Why track hydration?",
        "Help me sleep better",
        "Explain today's tasks"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemGroupedBackground),
                        Color.accentColor.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 14) {
                                ForEach(messages) { message in
                                    AssistantBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 16)
                            .padding(.bottom, 14)
                        }
                        .onChange(of: messages.count) { _, _ in
                            guard let last = messages.last else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }

                    quickPromptBar
                    if isWaitingForReply {
                        thinkingIndicator
                    }
                    composer
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("BioMesh Assistant")
                        .font(.system(size: 28, weight: .bold))
                    Text("Simple guidance for caffeine, anxiety, hydration, and sleep.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    private var quickPromptBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(quickPrompts, id: \.self) { prompt in
                    Button(prompt) {
                        send(prompt)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(.white.opacity(0.9))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
    }

    private var thinkingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("BioMesh Assistant is thinking...")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }

    private var composer: some View {
        HStack(spacing: 12) {
            TextField("Ask about caffeine, sleep, anxiety...", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .submitLabel(.send)
                .onSubmit {
                    send(draft)
                }

            Button {
                send(draft)
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray.opacity(0.45) : Color.accentColor)
                    .clipShape(Circle())
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isWaitingForReply)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(.ultraThinMaterial)
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(AssistantMessage(text: trimmed, isUser: true))
        draft = ""

        isWaitingForReply = true
        Task {
            let reply = await BioMeshAssistantService.reply(to: trimmed)
            messages.append(AssistantMessage(text: reply, isUser: false))
            isWaitingForReply = false
        }
    }
}

private struct AssistantBubble: View {
    let message: AssistantMessage

    var body: some View {
        HStack(alignment: .bottom) {
            if message.isUser {
                Spacer(minLength: 48)
            }

            Text(message.text)
                .font(.body)
                .foregroundStyle(message.isUser ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(message.isUser ? Color.accentColor : Color.white)
                .clipShape(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .shadow(color: .black.opacity(message.isUser ? 0.08 : 0.05), radius: 10, y: 4)

            if !message.isUser {
                Spacer(minLength: 48)
            }
        }
    }
}

private struct AssistantMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool

    static let starterMessages = [
        AssistantMessage(
            text: "Hi, I can help interpret your BioMesh tasks. Try asking about caffeine, anxiety, hydration, sleep, or what to log today.",
            isUser: false
        )
    ]
}

private enum BioMeshAssistantEngine {
    static func reply(to text: String) -> String {
        let lowercased = text.lowercased()

        if lowercased.contains("caffeine") || lowercased.contains("coffee") || lowercased.contains("tea") {
            return "If caffeine feels high today, log each drink, avoid more caffeine after early afternoon, drink water, and watch for anxiety or sleep changes. BioMesh treats >400 mg/day as a higher-risk signal."
        }

        if lowercased.contains("anxiety") || lowercased.contains("stress") || lowercased.contains("panic") {
            return "Use Anxiety Check-in when symptoms show up. A useful note is how long ago you last had caffeine, plus hydration and sleep context. That helps connect patterns instead of guessing."
        }

        if lowercased.contains("hydration") || lowercased.contains("water") || lowercased.contains("dehydration") {
            return "Hydration is a control signal: low water intake can feel like caffeine jitters. Try logging Hydration Checkpoint before judging whether caffeine caused the symptoms."
        }

        if lowercased.contains("sleep") || lowercased.contains("bed") || lowercased.contains("wind") {
            return "For sleep, complete Evening Wind-Down: no caffeine after 2 PM, dim lights before bed, and put your phone face-down. Sleep Duration helps show whether caffeine affects next-day anxiety."
        }

        if lowercased.contains("task") || lowercased.contains("today") || lowercased.contains("log") {
            return "Today, focus on logging caffeine intake, hydration, anxiety episodes, and any HealthKit signals like steps, heart rate, and sleep. The goal is to build a pattern, not judge one day."
        }

        return "I can help with BioMesh guidance, but I am rule-based for this demo. Ask about caffeine, anxiety, hydration, sleep, or today's tasks and I will give a practical next step."
    }
}

private enum BioMeshAssistantService {
    private static let endpoint = URL(string: "https://api.openai.com/v1/responses")!
    private static let model = "gpt-5.4-mini"

    // For a local demo, you can paste your key here. Do not commit a real key.
    private static let localAPIKey = ""

    static func reply(to text: String) async -> String {
        guard let apiKey else {
            return BioMeshAssistantEngine.reply(to: text)
        }

        do {
            return try await requestOpenAIReply(to: text, apiKey: apiKey)
        } catch {
            let fallback = BioMeshAssistantEngine.reply(to: text)
            return "\(fallback)\n\nAPI note: I could not reach OpenAI, so I used the local fallback response."
        }
    }

    private static var apiKey: String? {
        let environmentKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let environmentKey,
           !environmentKey.isEmpty {
            return environmentKey
        }

        let trimmedLocalKey = localAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedLocalKey.isEmpty ? nil : trimmedLocalKey
    }

    private static func requestOpenAIReply(
        to text: String,
        apiKey: String
    ) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": model,
            "max_output_tokens": 120,
            "instructions": """
            You are BioMesh Assistant, a concise helper inside a caffeine, anxiety, hydration, sleep, and activity tracking app. Give practical, non-diagnostic guidance in 2-4 short sentences. Encourage users to log relevant tasks in the app. Do not claim to provide medical diagnosis or emergency care.
            """,
            "input": text
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try extractReplyText(from: data)
    }

    private static func extractReplyText(from data: Data) throws -> String {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        if let outputText = object["output_text"] as? String,
           !outputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return outputText
        }

        if let output = object["output"] as? [[String: Any]] {
            let texts = output
                .compactMap { item -> [[String: Any]]? in
                    item["content"] as? [[String: Any]]
                }
                .flatMap { $0 }
                .compactMap { content in
                    content["text"] as? String
                }
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

            if !texts.isEmpty {
                return texts.joined(separator: "\n\n")
            }
        }

        throw URLError(.cannotParseResponse)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(loginViewModel: .init())
			.environment(\.appDelegate, AppDelegate())
            .environment(\.careStore, Utility.createPreviewStore())
			.careKitStyle(Styler())
    }
}
