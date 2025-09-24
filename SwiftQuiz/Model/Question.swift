//
//  Question.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import Foundation

enum QuestionType: String, Codable {
    case multipleChoice
    case shortAnswer
    case freeform
}

extension Question {
    // Computed property for transformable `choices`
    var choiceList: [String] {
        get { choices ?? [] }
        set { choices = newValue }
    }

    // Enum conversion for `type`
    var questionTypeEnum: QuestionType? {
        guard let raw = type else { return nil }
        return QuestionType(rawValue: raw)
    }

    var isMultipleChoice: Bool {
        self.questionTypeEnum == .multipleChoice
    }

    /// Check if this question should be retried based on previous answer
    func shouldRetry(thresholdHours: TimeInterval = 48) -> Bool {
        guard let userAnswer = self.userAnswer else {
            // No previous answer - question is available
            return true
        }

        guard let timestamp = userAnswer.timestamp else {
            // No timestamp - treat as available
            return true
        }

        let timeSinceAnswer = Date().timeIntervalSince(timestamp) / 3600 // Convert to hours
        let isRecentAnswer = timeSinceAnswer < thresholdHours

        // If answer is recent and was correct (not partial), don't retry
        if isRecentAnswer, userAnswer.isCorrect == true, userAnswer.isPartial != true {
            return false
        }

        // Retry if: answer was wrong, partial, or enough time has passed
        return true
    }
}

// Extension for Question to provide type description
extension Question {
    var typeDescription: String {
        switch self.type {
        case "multipleChoice", "multiple_choice":
            "Multiple Choice"
        case "shortAnswer", "short_answer":
            "Short Answer"
        case "freeform":
            "Long Form"
        default:
            "Unknown"
        }
    }
}
