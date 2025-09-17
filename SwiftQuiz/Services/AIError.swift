//
//  AIError.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/17/25.
//

import Foundation

enum AIProvider: String, CaseIterable {
    case claude = "Claude"
    case openai = "OpenAI"
    case disabled = "None"
}

enum AIError: Error, LocalizedError {
    case missingAPIKey
    case networkError
    case httpError(statusCode: Int, message: String?, rawData: Data?)
    case rateLimited(retryAfter: TimeInterval?)
    case serverError(statusCode: Int, message: String?)
    case invalidResponse(reason: String)
    case decodingError(underlying: Error)
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "API key is missing. Please configure it in Settings."
        case .networkError:
            "Network error. Please check your internet connection."
        case let .httpError(statusCode, message, _):
            if let message {
                "HTTP \(statusCode): \(message)"
            } else {
                "HTTP error \(statusCode). Please try again."
            }
        case let .rateLimited(retryAfter):
            if let retryAfter {
                "Rate limited. Please wait \(Int(retryAfter)) seconds and try again."
            } else {
                "Too many requests. Please wait a moment and try again."
            }
        case let .serverError(statusCode, message):
            if let message {
                "Server error \(statusCode): \(message)"
            } else {
                "AI service is temporarily unavailable. Please try again later."
            }
        case let .invalidResponse(reason):
            "Invalid response from AI service: \(reason)"
        case let .decodingError(underlying):
            "Failed to parse response: \(underlying.localizedDescription)"
        case .requestFailed:
            "Request failed. Please check your internet connection."
        }
    }

    var statusCode: Int? {
        switch self {
        case let .httpError(statusCode, _, _), let .serverError(statusCode, _):
            statusCode
        default:
            nil
        }
    }

    var rawData: Data? {
        switch self {
        case let .httpError(_, _, rawData):
            rawData
        default:
            nil
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkError, .serverError, .rateLimited:
            true
        case let .httpError(statusCode, _, _):
            statusCode >= 500
        default:
            false
        }
    }
}
