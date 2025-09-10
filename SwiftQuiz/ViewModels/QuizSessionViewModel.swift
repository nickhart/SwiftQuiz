//
//  QuizSessionViewModel.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import CoreData
import SwiftUI

class QuizSessionViewModel: ObservableObject {
    @Published var questions: [Question] = []
    @Published var currentIndex: Int = 0
    @Published var userAnswer: UserAnswer?

    var context: NSManagedObjectContext?

    var currentQuestion: Question? {
        get {
            guard self.questions.indices.contains(self.currentIndex) else { return nil }
            return self.questions[self.currentIndex]
        }
        set {
            if let newQuestion = newValue,
               let index = questions.firstIndex(of: newQuestion) {
                self.currentIndex = index
            }
        }
    }

    var hasRemainingQuestions: Bool {
        self.currentQuestion != nil
    }

    init() {
        // Context will be injected later
    }

    func setup(with context: NSManagedObjectContext) {
        self.context = context
        self.fetchQuestions()
        self.advanceToNextUnanswered()
    }

    func fetchQuestions() {
        guard let context else { return }
        let request: NSFetchRequest<Question> = Question.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "question", ascending: true)]
        request.predicate = NSPredicate(format: "userAnswer == nil")
        do {
            self.questions = try context.fetch(request)
        } catch {
            print("Error fetching questions: \(error)")
        }
    }

    func submitAnswer(_ text: String) {
        guard let question = currentQuestion,
              let context else { return }

        let answer = UserAnswer(context: context)
        answer.answer = text
        answer.timestamp = Date()
        answer.question = question

        self.userAnswer = answer

        do {
            try context.save()
        } catch {
            print("Failed to save answer: \(error)")
        }

        self.advanceToNextUnanswered()
    }

    func advanceToNextUnanswered() {
        let nextIndex = self.questions.firstIndex(where: { $0.userAnswer == nil })
        if let index = nextIndex {
            self.currentIndex = index
            self.userAnswer = nil
        } else {
            print("No more unanswered questions")
        }
    }
}
