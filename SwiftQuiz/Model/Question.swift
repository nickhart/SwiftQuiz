//
//  Question.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import Foundation

enum QuestionType: String, Codable {
    case bool
    case multipleChoice
    case shortAnswer
    case freeform
}

extension Question {
    // Computed property for transformable `choices`
    var choiceList: [String] {
        get { (choices as? [String]) ?? [] }
        set { choices = newValue as NSObject } // Optional: cast to NSObject if needed
    }

    // Computed property for transformable `tags`
    var tagList: [String] {
        get { (tags as? [String]) ?? [] }
        set { tags = newValue as NSObject }
    }

    // Enum conversion for `type`
    var questionTypeEnum: QuestionType? {
        guard let raw = type else { return nil }
        return QuestionType(rawValue: raw)
    }
}
