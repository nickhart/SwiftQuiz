//
//  AIService.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/15/25.
//

import Combine
import Foundation

// swiftlint:disable file_types_order

@MainActor
class AIService: ObservableObject {
    static let shared = AIService()

    @Published var currentProvider: AIProvider = .claude
    @Published var claudeAPIKey: String = ""
    @Published var openAIAPIKey: String = ""

    private let settingsService: SettingsService
    private var cancellables = Set<AnyCancellable>()

    init(settingsService: SettingsService = .shared) {
        print("🤖 AIService: Initializing...")

        self.settingsService = settingsService

        // Bind to settings service
        self.bindToSettingsService()

        print("🤖 AIService: Initialized with provider: \(self.currentProvider)")
        print("🤖 AIService: Claude key available: \(!self.claudeAPIKey.isEmpty)")
        print("🤖 AIService: OpenAI key available: \(!self.openAIAPIKey.isEmpty)")
    }

    func updateProvider(_ provider: AIProvider) {
        print("🤖 AIService: Delegating provider update to SettingsService")
        self.settingsService.updateProvider(provider)
    }

    func updateClaudeAPIKey(_ key: String) {
        print("🤖 AIService: Delegating Claude API key update to SettingsService")
        self.settingsService.updateClaudeAPIKey(key)
    }

    func updateOpenAIAPIKey(_ key: String) {
        print("🤖 AIService: Delegating OpenAI API key update to SettingsService")
        self.settingsService.updateOpenAIAPIKey(key)
    }

    private func bindToSettingsService() {
        // Bind provider
        self.settingsService.$aiProvider
            .receive(on: RunLoop.main)
            .assign(to: \.currentProvider, on: self)
            .store(in: &self.cancellables)

        // Bind Claude API key
        self.settingsService.$claudeAPIKey
            .receive(on: RunLoop.main)
            .assign(to: \.claudeAPIKey, on: self)
            .store(in: &self.cancellables)

        // Bind OpenAI API key
        self.settingsService.$openAIAPIKey
            .receive(on: RunLoop.main)
            .assign(to: \.openAIAPIKey, on: self)
            .store(in: &self.cancellables)
    }

    func testClaudeAuthentication() async -> String {
        print("🧪 AIService: Delegating authentication test to SettingsService")
        return await self.settingsService.testClaudeAuthentication()
    }

    func evaluateAnswer(question: String, userAnswer: String, correctAnswer: String) async throws -> String {
        print("🤖 AIService: Starting evaluation with provider: \(self.currentProvider)")
        print("🤖 AIService: Question length: \(question.count), User answer length: \(userAnswer.count)")

        switch self.currentProvider {
        case .claude:
            return try await self.evaluateWithClaude(
                question: question,
                userAnswer: userAnswer,
                correctAnswer: correctAnswer
            )
        case .openai:
            return try await self.evaluateWithOpenAI(
                question: question,
                userAnswer: userAnswer,
                correctAnswer: correctAnswer
            )
        case .disabled:
            print("🤖 AIService: AI evaluation is disabled")
            return "AI evaluation is disabled. Enable it in Settings to get detailed feedback."
        }
    }

    private func evaluateWithClaude(question: String,
                                    userAnswer: String,
                                    correctAnswer: String) async throws -> String {
        print("🤖 AIService: Evaluating with Claude API")
        guard !self.claudeAPIKey.isEmpty else {
            print("❌ AIService: Claude API key is missing")
            throw AIError.missingAPIKey
        }

        print("🤖 AIService: Using Claude API key: \(self.claudeAPIKey.prefix(10))...")
        print("🤖 AIService: Key starts with 'sk-ant-': \(self.claudeAPIKey.hasPrefix("sk-ant-"))")
        print("🤖 AIService: Key length: \(self.claudeAPIKey.count)")

        let prompt = """
        You are helping evaluate a Swift programming quiz answer.

        Question: \(question)
        User's Answer: \(userAnswer)
        Expected Answer: \(correctAnswer)

        Please provide a brief evaluation (2-3 sentences) of the user's answer. \
        If correct, acknowledge it and perhaps add a helpful tip. If incorrect, \
        explain what's wrong and guide them toward the right answer.
        """

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue(self.claudeAPIKey, forHTTPHeaderField: "x-api-key")

        print("🤖 AIService: Request headers:")
        print("🤖 AIService: Content-Type: application/json")
        print("🤖 AIService: anthropic-version: 2023-06-01")
        print("🤖 AIService: x-api-key: \(self.claudeAPIKey.prefix(10))...")

        let requestBody = ClaudeRequest(
            model: "claude-3-haiku-20240307",
            maxTokens: 150,
            messages: [
                ClaudeMessage(role: "user", content: prompt),
            ]
        )

        request.httpBody = try JSONEncoder().encode(requestBody)

        print("🤖 AIService: Sending request to Claude API...")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ AIService: Invalid HTTP response")
            throw AIError.requestFailed
        }

        print("🤖 AIService: Claude API response status: \(httpResponse.statusCode)")
        guard httpResponse.statusCode == 200 else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("❌ AIService: Claude API error: \(errorData)")
            }
            throw AIError.requestFailed
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        let result = claudeResponse.content.first?.text ?? "Unable to evaluate answer"
        print("✅ AIService: Claude evaluation completed (length: \(result.count))")
        return result
    }

    private func evaluateWithOpenAI(question: String,
                                    userAnswer: String,
                                    correctAnswer: String) async throws -> String {
        print("🤖 AIService: Evaluating with OpenAI API")
        guard !self.openAIAPIKey.isEmpty else {
            print("❌ AIService: OpenAI API key is missing")
            throw AIError.missingAPIKey
        }

        print("🤖 AIService: Using OpenAI API key: \(self.openAIAPIKey.prefix(10))...")
        print("🤖 AIService: Key starts with 'sk-': \(self.openAIAPIKey.hasPrefix("sk-"))")
        print("🤖 AIService: Key length: \(self.openAIAPIKey.count)")

        let prompt = """
        You are helping evaluate a Swift programming quiz answer.

        Question: \(question)
        User's Answer: \(userAnswer)
        Expected Answer: \(correctAnswer)

        Please provide a brief evaluation (2-3 sentences) of the user's answer. \
        If correct, acknowledge it and perhaps add a helpful tip. If incorrect, \
        explain what's wrong and guide them toward the right answer.
        """

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(self.openAIAPIKey)", forHTTPHeaderField: "Authorization")

        print("🤖 AIService: Request headers:")
        print("🤖 AIService: Content-Type: application/json")
        print("🤖 AIService: Authorization: Bearer \(self.openAIAPIKey.prefix(10))...")

        let requestBody = OpenAIRequest(
            model: "gpt-4o-mini",
            messages: [
                OpenAIMessage(role: "user", content: prompt),
            ],
            maxTokens: 150
        )

        request.httpBody = try JSONEncoder().encode(requestBody)

        print("🤖 AIService: Sending request to OpenAI API...")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ AIService: Invalid HTTP response")
            throw AIError.requestFailed
        }

        print("🤖 AIService: OpenAI API response status: \(httpResponse.statusCode)")
        guard httpResponse.statusCode == 200 else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("❌ AIService: OpenAI API error: \(errorData)")
            }
            throw AIError.requestFailed
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let result = openAIResponse.choices.first?.message.content ?? "Unable to evaluate answer"
        print("✅ AIService: OpenAI evaluation completed (length: \(result.count))")
        return result
    }
}

// MARK: - Claude API Models

struct ClaudeRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
    }
}

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeResponse: Codable {
    let content: [ClaudeContent]
}

struct ClaudeContent: Codable {
    let text: String
}

// MARK: - OpenAI API Models

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

enum AIProvider: String, CaseIterable {
    case claude = "Claude"
    case openai = "OpenAI"
    case disabled = "None"
}

enum AIError: Error {
    case missingAPIKey
    case requestFailed
    case invalidResponse
}

// swiftlint:enable file_types_order
