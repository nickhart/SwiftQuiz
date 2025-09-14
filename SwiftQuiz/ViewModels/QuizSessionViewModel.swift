//
//  QuizSessionViewModel.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import Combine
import CoreData
import SwiftUI

class QuizSessionViewModel: ObservableObject {
    @Published var questions: [Question] = []
    @Published var currentIndex: Int = 0
    @Published var userAnswer: UserAnswer?
    @Published var currentQuestion: Question?
    @Published var currentUserInput: String = ""

    var context: NSManagedObjectContext?
    private var cancellables = Set<AnyCancellable>()

    // Configurable retry threshold for incorrect answers (in hours)
    private let retryThresholdHours: TimeInterval = 48

    var hasRemainingQuestions: Bool {
        !self.getAvailableQuestions().isEmpty
    }

    init() {
        // Context will be injected later
    }

    func setup(with context: NSManagedObjectContext, mainViewModel: MainViewModel) {
        self.context = context
        self.fetchQuestions()
        self.selectNextQuestion()

        // Observe loading state changes to refetch questions when import completes
        mainViewModel.$loadingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loadingState in
                if case .loaded = loadingState {
                    self?.refetchQuestionsAfterImport()
                }
            }
            .store(in: &self.cancellables)
    }

    // Backward compatibility method
    func setup(with context: NSManagedObjectContext) {
        self.context = context
        self.fetchQuestions()
        self.selectNextQuestion()
        print("Warning: Using setup without MainViewModel - loading state observation disabled")
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

        self.selectNextQuestion()
    }

    private func getAvailableQuestions() -> [Question] {
        guard let context else { return [] }

        // Primary pool: questions never answered
        let unansweredRequest: NSFetchRequest<Question> = Question.fetchRequest()
        unansweredRequest.predicate = NSPredicate(format: "userAnswer == nil")

        do {
            let unansweredQuestions = try context.fetch(unansweredRequest)
            if !unansweredQuestions.isEmpty {
                return unansweredQuestions
            }
        } catch {
            print("Error fetching unanswered questions: \(error)")
        }

        // Secondary pool: questions answered incorrectly more than retryThresholdHours ago
        let retryThreshold = Date().addingTimeInterval(-self.retryThresholdHours * 3600)
        let retryRequest: NSFetchRequest<Question> = Question.fetchRequest()
        retryRequest.predicate = NSPredicate(
            format: "userAnswer.isCorrect == NO AND userAnswer.timestamp < %@",
            retryThreshold as NSDate
        )

        do {
            let retryQuestions = try context.fetch(retryRequest)
            return retryQuestions
        } catch {
            print("Error fetching retry questions: \(error)")
            return []
        }
    }

    func selectNextQuestion() {
        let availableQuestions = self.getAvailableQuestions()

        guard !availableQuestions.isEmpty else {
            print("No questions available")
            self.currentQuestion = nil
            self.userAnswer = nil
            self.currentUserInput = ""
            return
        }

        // Randomly select from available questions
        let selectedQuestion = availableQuestions.randomElement()
        self.currentQuestion = selectedQuestion
        self.userAnswer = nil
        self.currentUserInput = "" // Clear input when changing questions

        // Update the questions array and currentIndex for compatibility with existing UI
        if let selected = selectedQuestion,
           let index = self.questions.firstIndex(of: selected) {
            self.currentIndex = index
        }
    }

    func advanceToNextUnanswered() {
        self.selectNextQuestion()
    }

    private func refetchQuestionsAfterImport() {
        print("Refetching questions after import completion...")
        self.fetchQuestions()
        self.selectNextQuestion()
        print("Questions refetched: \(self.questions.count) available")
    }
}
