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

        // Create or update UserAnswer
        let answer: UserAnswer
        if let existingAnswer = question.userAnswer {
            answer = existingAnswer
        } else {
            answer = UserAnswer(context: context)
            answer.question = question
            answer.questionID = question.id
        }

        answer.answer = text
        answer.timestamp = Date()
        answer.interactionTypeEnum = .answered

        // Auto-evaluate correctness for multiple choice and short answer questions
        if let questionType = question.questionTypeEnum,
           let correctAnswer = question.answer {
            switch questionType {
            case .multipleChoice:
                answer.isCorrect = (text == correctAnswer)
            case .shortAnswer:
                let userText = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let correctText = correctAnswer.lowercased()
                answer.isCorrect = (userText == correctText)
            case .freeform:
                // For freeform questions, default to false until AI evaluation
                answer.isCorrect = false
            }
        } else {
            answer.isCorrect = false
        }

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

        // Fetch all questions
        let allQuestionsRequest: NSFetchRequest<Question> = Question.fetchRequest()

        do {
            let allQuestions = try context.fetch(allQuestionsRequest)
            let availableQuestions = allQuestions.filter { question in
                // Never interacted with - always available
                guard let userAnswer = question.userAnswer else { return true }

                // Use the UserAnswer extension to check if should retry
                return userAnswer.shouldRetry(thresholdHours: self.retryThresholdHours)
            }

            print("📊 Question availability: \\(availableQuestions.count)/\\(allQuestions.count) available")
            return availableQuestions
        } catch {
            print("Error fetching questions: \\(error)")
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

    func skipCurrentQuestion() {
        guard let question = currentQuestion,
              let context else { return }

        // Create or update UserAnswer to record the skip
        let userAnswer: UserAnswer
        if let existingAnswer = question.userAnswer {
            userAnswer = existingAnswer
        } else {
            userAnswer = UserAnswer(context: context)
            userAnswer.question = question
            userAnswer.questionID = question.id
        }

        // Mark as skipped
        userAnswer.interactionTypeEnum = .skipped
        userAnswer.timestamp = Date()
        userAnswer.answer = nil // No answer for skipped questions
        userAnswer.isCorrect = false // Skipped questions are not correct

        do {
            try context.save()
            print("✅ Question skipped and saved")
        } catch {
            print("❌ Failed to save skipped question: \\(error)")
        }

        // Move to next question
        self.selectNextQuestion()
    }

    private func refetchQuestionsAfterImport() {
        print("Refetching questions after import completion...")
        self.fetchQuestions()
        self.selectNextQuestion()
        print("Questions refetched: \(self.questions.count) available")
    }
}
