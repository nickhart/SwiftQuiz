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

    // Computed property for transformable `tags`
    var tagList: [String] {
        get { tags ?? [] }
        set { tags = newValue }
    }

    var primaryTag: String? {
        self.tagList.first
    }

    // Enum conversion for `type`
    var questionTypeEnum: QuestionType? {
        guard let raw = type else { return nil }
        return QuestionType(rawValue: raw)
    }

    var isMultipleChoice: Bool {
        self.questionTypeEnum == .multipleChoice
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
