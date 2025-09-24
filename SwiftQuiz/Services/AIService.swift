//
//  AIService.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/15/25.
//

import Combine
import Foundation

@MainActor
class AIService: ObservableObject {
    static let shared = AIService(settingsService: SettingsService.shared)

    @Published var currentProvider: AIProvider = .claude
    @Published var claudeAPIKey: String = ""
    @Published var openAIAPIKey: String = ""

    private let settingsService: SettingsService
    private var cancellables = Set<AnyCancellable>()

    init(settingsService: SettingsService) {
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
        // For now, just sync the values directly since we don't have publishers for API keys
        // We may need to add proper binding later when the new architecture is complete
        self.claudeAPIKey = self.settingsService.claudeAPIKey
        self.openAIAPIKey = self.settingsService.openAIAPIKey

        // Set up a timer to periodically sync (temporary solution)
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.claudeAPIKey = self.settingsService.claudeAPIKey
                self.openAIAPIKey = self.settingsService.openAIAPIKey
            }
        }

        // Store timer in cancellables for cleanup
        AnyCancellable {
            timer.invalidate()
        }.store(in: &self.cancellables)
    }

    func testClaudeAuthentication() async -> String {
        print("🧪 AIService: Delegating authentication test to SettingsService")
        return await self.settingsService.testClaudeAuthentication(apiKey: self.claudeAPIKey)
    }

    func evaluateAnswer(question: String, userAnswer: String, correctAnswer: String) async throws -> String {
        print("🤖 AIService: Starting evaluation with provider: \(self.currentProvider)")
        print("🤖 AIService: Question length: \(question.count), User answer length: \(userAnswer.count)")

        switch self.currentProvider {
        case .claude:
            guard !self.claudeAPIKey.isEmpty else {
                throw AIError.missingAPIKey
            }
            let config = AIProviderConfig.claude(apiKey: self.claudeAPIKey)
            return try await self.evaluateWithProvider(
                config: config,
                question: question,
                userAnswer: userAnswer,
                correctAnswer: correctAnswer
            )
        case .openai:
            guard !self.openAIAPIKey.isEmpty else {
                throw AIError.missingAPIKey
            }
            let config = AIProviderConfig.openAI(apiKey: self.openAIAPIKey)
            return try await self.evaluateWithProvider(
                config: config,
                question: question,
                userAnswer: userAnswer,
                correctAnswer: correctAnswer
            )
        case .disabled:
            print("🤖 AIService: AI evaluation is disabled")
            return "AI evaluation is disabled. Enable it in Settings to get detailed feedback."
        }
    }

    func evaluateQuizSession(_ session: QuizSession) async throws -> QuizEvaluationResult {
        print("🤖 AIService: Starting quiz session evaluation with provider: \(self.currentProvider)")
        print("🤖 AIService: Session contains \(session.questions.count) questions")

        switch self.currentProvider {
        case .claude:
            guard !self.claudeAPIKey.isEmpty else {
                throw AIError.missingAPIKey
            }
            let config = AIProviderConfig.claudeQuizEvaluation(apiKey: self.claudeAPIKey)
            return try await self.evaluateQuizWithProvider(config: config, session: session)
        case .openai:
            guard !self.openAIAPIKey.isEmpty else {
                throw AIError.missingAPIKey
            }
            let config = AIProviderConfig.openAIQuizEvaluation(apiKey: self.openAIAPIKey)
            return try await self.evaluateQuizWithProvider(config: config, session: session)
        case .disabled:
            print("🤖 AIService: AI evaluation is disabled")
            throw AIError.missingAPIKey
        }
    }

    private func evaluateWithProvider(config: AIProviderConfig, question: String, userAnswer: String,
                                      correctAnswer: String) async throws -> String {
        print("🤖 AIService: Evaluating with \(config.name) API")

        let promptData = PromptData(
            question: question,
            userAnswer: userAnswer,
            correctAnswer: correctAnswer,
            maxTokens: 150
        )

        var request = URLRequest(url: URL(string: config.baseURL)!)
        request.httpMethod = "POST"

        // Set headers from config
        let headers = config.headers("")
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }

        // Encode request body using config
        request.httpBody = try config.requestEncoder(promptData)

        print("🤖 AIService: Sending request to \(config.name) API...")
        return try await self.performRequestWithRetry(request: request, config: config)
    }

    private func evaluateQuizWithProvider(config: AIProviderConfig,
                                          session: QuizSession) async throws -> QuizEvaluationResult {
        print("🤖 AIService: Evaluating quiz session with \(config.name) API")

        let quizData = QuizSessionData(session: session)

        var request = URLRequest(url: URL(string: config.baseURL)!)
        request.httpMethod = "POST"

        // Set headers from config
        let headers = config.headers("")
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }

        // Encode request body using config
        request.httpBody = try config.requestEncoder(quizData)

        print("🤖 AIService: Sending quiz evaluation request to \(config.name) API...")
        return try await self.performQuizRequestWithRetry(request: request, config: config, session: session)
    }

    private func performQuizRequestWithRetry(request: URLRequest, config: AIProviderConfig, session: QuizSession,
                                             retryCount: Int = 0) async throws -> QuizEvaluationResult {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ AIService: Invalid HTTP response")
                throw AIError.networkError
            }

            print("🤖 AIService: \(config.name) API response status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                throw self.handleHTTPError(httpResponse, data: data, config: config)
            }

            do {
                let result = try config.quizResponseDecoder!(data, session)
                print("✅ AIService: \(config.name) quiz evaluation completed")
                return result
            } catch {
                print("❌ AIService: Failed to decode \(config.name) quiz response: \(error)")
                throw AIError.decodingError(underlying: error)
            }
        } catch let error as AIError {
            if error.isRetryable, retryCount < 2 {
                print("🔄 AIService: \(config.name) quiz request failed (attempt \(retryCount + 1)/3), retrying...")
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000))
                return try await performQuizRequestWithRetry(
                    request: request,
                    config: config,
                    session: session,
                    retryCount: retryCount + 1
                )
            }
            throw error
        } catch {
            if retryCount < 2 {
                print("🔄 AIService: \(config.name) quiz request failed (attempt \(retryCount + 1)/3), retrying...")
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000))
                return try await self.performQuizRequestWithRetry(
                    request: request,
                    config: config,
                    session: session,
                    retryCount: retryCount + 1
                )
            }
            throw AIError.networkError
        }
    }

    private func performRequestWithRetry(request: URLRequest, config: AIProviderConfig,
                                         retryCount: Int = 0) async throws -> String {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ AIService: Invalid HTTP response")
                throw AIError.networkError
            }

            print("🤖 AIService: \(config.name) API response status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                throw self.handleHTTPError(httpResponse, data: data, config: config)
            }

            do {
                let result = try config.responseDecoder(data)
                print("✅ AIService: \(config.name) evaluation completed (length: \(result.count))")
                return result
            } catch {
                print("❌ AIService: Failed to decode \(config.name) response: \(error)")
                throw AIError.decodingError(underlying: error)
            }
        } catch let error as AIError {
            if error.isRetryable, retryCount < 2 {
                print("🔄 AIService: \(config.name) request failed (attempt \(retryCount + 1)/3), retrying...")
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000))
                return try await performRequestWithRetry(request: request, config: config, retryCount: retryCount + 1)
            }
            throw error
        } catch {
            if retryCount < 2 {
                print("🔄 AIService: \(config.name) request failed (attempt \(retryCount + 1)/3), retrying...")
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000))
                return try await self.performRequestWithRetry(
                    request: request,
                    config: config,
                    retryCount: retryCount + 1
                )
            }
            throw AIError.networkError
        }
    }

    // MARK: - Error Handling

    private func handleHTTPError(_ response: HTTPURLResponse, data: Data, config: AIProviderConfig) -> AIError {
        let statusCode = response.statusCode
        let errorMessage = config.errorParser(statusCode, data)

        switch statusCode {
        case 401, 403:
            return .missingAPIKey
        case 429:
            let retryAfter = self.extractRetryAfter(response)
            return .rateLimited(retryAfter: retryAfter)
        case 500...599:
            return .serverError(statusCode: statusCode, message: errorMessage)
        default:
            return .httpError(statusCode: statusCode, message: errorMessage, rawData: data)
        }
    }

    private func extractRetryAfter(_ response: HTTPURLResponse) -> TimeInterval? {
        if let retryAfterString = response.value(forHTTPHeaderField: "Retry-After"),
           let retryAfter = TimeInterval(retryAfterString) {
            return retryAfter
        }
        return nil
    }
}
