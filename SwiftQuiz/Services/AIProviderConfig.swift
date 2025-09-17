//
//  AIProviderConfig.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/17/25.
//

import Foundation

// MARK: - Supporting Types

struct PromptData {
    let question: String
    let userAnswer: String
    let correctAnswer: String
    let maxTokens: Int
}

// MARK: - Claude API Models

struct ClaudeAPIRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeAPIMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
    }
}

struct ClaudeAPIMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeAPIResponse: Codable {
    let content: [ClaudeAPIContent]
}

struct ClaudeAPIContent: Codable {
    let text: String
}

// MARK: - OpenAI API Models

struct OpenAIAPIRequest: Codable {
    let model: String
    let messages: [OpenAIAPIMessage]
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
    }
}

struct OpenAIAPIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIAPIResponse: Codable {
    let choices: [OpenAIAPIChoice]
}

struct OpenAIAPIChoice: Codable {
    let message: OpenAIAPIMessage
}

// MARK: - Main Type

struct AIProviderConfig {
    let name: String
    let baseURL: String
    let headers: (String) -> [String: String]
    let requestEncoder: (PromptData) throws -> Data
    let responseDecoder: (Data) throws -> String
    let errorParser: (Int, Data) -> String?
}

// MARK: - Extension

extension AIProviderConfig {
    static func claude(apiKey: String) -> AIProviderConfig {
        AIProviderConfig(
            name: "Claude",
            baseURL: "https://api.anthropic.com/v1/messages",
            headers: { _ in
                [
                    "Content-Type": "application/json",
                    "anthropic-version": "2023-06-01",
                    "x-api-key": apiKey,
                ]
            },
            requestEncoder: { promptData in
                let prompt = createEnhancedPrompt(
                    question: promptData.question,
                    userAnswer: promptData.userAnswer,
                    correctAnswer: promptData.correctAnswer
                )

                let request = ClaudeAPIRequest(
                    model: "claude-3-haiku-20240307",
                    maxTokens: promptData.maxTokens,
                    messages: [
                        ClaudeAPIMessage(role: "user", content: prompt),
                    ]
                )

                do {
                    return try JSONEncoder().encode(request)
                } catch {
                    throw error
                }
            },
            responseDecoder: { data in
                let response = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
                return response.content.first?.text ?? "Unable to evaluate answer"
            },
            errorParser: { _, data in
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    return message
                }
                return String(data: data, encoding: .utf8)
            }
        )
    }

    static func openAI(apiKey: String) -> AIProviderConfig {
        AIProviderConfig(
            name: "OpenAI",
            baseURL: "https://api.openai.com/v1/chat/completions",
            headers: { _ in
                [
                    "Content-Type": "application/json",
                    "Authorization": "Bearer \(apiKey)",
                ]
            },
            requestEncoder: { promptData in
                let prompt = createEnhancedPrompt(
                    question: promptData.question,
                    userAnswer: promptData.userAnswer,
                    correctAnswer: promptData.correctAnswer
                )

                let request = OpenAIAPIRequest(
                    model: "gpt-4o-mini",
                    messages: [
                        OpenAIAPIMessage(role: "user", content: prompt),
                    ],
                    maxTokens: promptData.maxTokens
                )

                do {
                    return try JSONEncoder().encode(request)
                } catch {
                    throw error
                }
            },
            responseDecoder: { data in
                let response = try JSONDecoder().decode(OpenAIAPIResponse.self, from: data)
                return response.choices.first?.message.content ?? "Unable to evaluate answer"
            },
            errorParser: { _, data in
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    return message
                }
                return String(data: data, encoding: .utf8)
            }
        )
    }
}

private func createEnhancedPrompt(question: String, userAnswer: String, correctAnswer: String) -> String {
    """
    You are a Swift programming instructor. A student just answered a quiz question.

    Question: \(question)

    Student answered: "\(userAnswer)"
    Expected answer: "\(correctAnswer)"

    Please provide specific, helpful feedback about their answer. Be direct and educational.

    - If correct: Acknowledge it and add a helpful tip
    - If incorrect: Explain what's wrong and guide toward the right answer
    - If partially correct: Point out what's right and what needs improvement

    Give your response in 2-3 clear sentences.
    Do not use placeholders or templates - give specific feedback about THIS answer.
    """
}
