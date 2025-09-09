//
//  QuestionCardViewModel.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import Foundation

class QuestionCardViewModel: ObservableObject {
    @Published var question: Question?

    init(question: Question? = nil) {
        self.question = question
    }
}
