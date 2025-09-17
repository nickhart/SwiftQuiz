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

struct QuizSessionData {
    let session: QuizSession

    init(session: QuizSession) {
        self.session = session
    }
}

enum AIConfigError: Error {
    case invalidDataType
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

private func createQuizEvaluationPrompt(session: QuizSession) -> String {
    var prompt = """
    You are a Swift programming instructor evaluating a student's quiz session.
    Please analyze their performance and provide structured feedback.

    QUIZ SESSION DETAILS:
    - Total Questions: \(session.questions.count)
    - Session Duration: \(session.duration.map { String(format: "%.1f minutes", $0 / 60) } ?? "In progress")

    QUESTIONS AND ANSWERS:
    """

    for (index, question) in session.questions.enumerated() {
        let answer = index < session.userAnswers.count ? session.userAnswers[index] : nil
        let userResponse = answer?.answer ?? "SKIPPED"

        prompt += """

        Question \(index + 1): \(question.question ?? "")
        Expected Answer: \(question.answer ?? "")
        Student Answer: \(userResponse)
        """
    }

    prompt += """

    Please provide your evaluation in this EXACT JSON format:
    {
        "overallScore": 0.85,
        "correctAnswers": 4,
        "skippedQuestions": 1,
        "individualResults": [
            {
                "questionIndex": 0,
                "isCorrect": true,
                "isSkipped": false,
                "feedback": "Excellent answer! You demonstrated understanding of..."
            }
        ],
        "insights": ["You show strong understanding of Swift fundamentals", "Good grasp of optionals"],
        "recommendations": ["Practice more with closures", "Review memory management"],
        "strengths": ["Strong basics", "Good problem-solving"],
        "areasForImprovement": ["Complex syntax", "Advanced concepts"]
    }

    IMPORTANT: Return ONLY the JSON, no additional text. Ensure all arrays have the correct number of elements.
    """

    return prompt
}

private func parseQuizEvaluationResponse(_ responseText: String, session: QuizSession) throws -> QuizEvaluationResult {
    // Clean the response to extract JSON
    let cleanedResponse = responseText
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "```json", with: "")
        .replacingOccurrences(of: "```", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    guard let jsonData = cleanedResponse.data(using: .utf8) else {
        throw AIConfigError.invalidDataType
    }

    do {
        let decoder = JSONDecoder()
        var result = try decoder.decode(QuizEvaluationResult.self, from: jsonData)

        // Set the session ID and timestamp
        result = QuizEvaluationResult(
            sessionId: session.id,
            overallScore: result.overallScore,
            totalQuestions: session.questions.count,
            correctAnswers: result.correctAnswers,
            skippedQuestions: result.skippedQuestions,
            individualResults: result.individualResults,
            insights: result.insights,
            recommendations: result.recommendations,
            strengths: result.strengths,
            areasForImprovement: result.areasForImprovement,
            evaluationTimestamp: Date()
        )

        return result
    } catch {
        print("❌ Failed to parse quiz evaluation JSON: \(error)")
        print("Response text: \(cleanedResponse)")
        throw error
    }
}

// MARK: - Main Type

struct AIProviderConfig {
    let name: String
    let baseURL: String
    let headers: (String) -> [String: String]
    let requestEncoder: (Any) throws -> Data
    let responseDecoder: (Data) throws -> String
    let quizResponseDecoder: ((Data, QuizSession) throws -> QuizEvaluationResult)?
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
            requestEncoder: { data in
                guard let promptData = data as? PromptData else {
                    throw AIConfigError.invalidDataType
                }

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
            quizResponseDecoder: nil,
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
            requestEncoder: { data in
                guard let promptData = data as? PromptData else {
                    throw AIConfigError.invalidDataType
                }

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
            quizResponseDecoder: nil,
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

    static func claudeQuizEvaluation(apiKey: String) -> AIProviderConfig {
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
            requestEncoder: { data in
                guard let quizData = data as? QuizSessionData else {
                    throw AIConfigError.invalidDataType
                }

                let prompt = createQuizEvaluationPrompt(session: quizData.session)

                let request = ClaudeAPIRequest(
                    model: "claude-3-haiku-20240307",
                    maxTokens: 2000,
                    messages: [
                        ClaudeAPIMessage(role: "user", content: prompt),
                    ]
                )

                return try JSONEncoder().encode(request)
            },
            responseDecoder: { _ in "" },
            quizResponseDecoder: { data, session in
                let response = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
                let responseText = response.content.first?.text ?? ""
                return try parseQuizEvaluationResponse(responseText, session: session)
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

    static func openAIQuizEvaluation(apiKey: String) -> AIProviderConfig {
        AIProviderConfig(
            name: "OpenAI",
            baseURL: "https://api.openai.com/v1/chat/completions",
            headers: { _ in
                [
                    "Content-Type": "application/json",
                    "Authorization": "Bearer \(apiKey)",
                ]
            },
            requestEncoder: { data in
                guard let quizData = data as? QuizSessionData else {
                    throw AIConfigError.invalidDataType
                }

                let prompt = createQuizEvaluationPrompt(session: quizData.session)

                let request = OpenAIAPIRequest(
                    model: "gpt-4o-mini",
                    messages: [
                        OpenAIAPIMessage(role: "user", content: prompt),
                    ],
                    maxTokens: 2000
                )

                return try JSONEncoder().encode(request)
            },
            responseDecoder: { _ in "" },
            quizResponseDecoder: { data, session in
                let response = try JSONDecoder().decode(OpenAIAPIResponse.self, from: data)
                let responseText = response.choices.first?.message.content ?? ""
                return try parseQuizEvaluationResponse(responseText, session: session)
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
