//
//  QuizSessionService.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/17/25.
//

import CoreData
import Foundation

enum QuizSessionError: Error, LocalizedError {
    case noQuestionsAvailable
    case sessionNotInProgress
    case evaluationFailed

    var errorDescription: String? {
        switch self {
        case .noQuestionsAvailable:
            "No questions are available for the quiz session."
        case .sessionNotInProgress:
            "No quiz session is currently in progress."
        case .evaluationFailed:
            "Failed to evaluate the quiz session."
        }
    }
}

@MainActor
class QuizSessionService: ObservableObject {
    private let context: NSManagedObjectContext
    private let aiService: AIService
    private let settingsService: SettingsService

    @Published var currentSession: QuizSession?
    @Published var lastEvaluationResult: QuizEvaluationResult?
    @Published var isEvaluating = false

    init(context: NSManagedObjectContext, aiService: AIService, settingsService: SettingsService) {
        self.context = context
        self.aiService = aiService
        self.settingsService = settingsService
    }

    func startQuizSession(config: QuizSessionConfig = QuizSessionConfig()) throws -> QuizSession {
        let questions = try selectQuestionsForQuiz(config: config)
        let session = QuizSession(questions: questions)
        self.currentSession = session
        return session
    }

    func submitAnswer(_ answer: String) {
        guard var session = currentSession else { return }
        session.addAnswer(answer, for: session.currentQuestionIndex)
        self.currentSession = session
    }

    func handleMaybeCompletedSession(_ session: QuizSession? = nil) {
        guard let session = session ?? currentSession else { return }

        if session.isCompleted {
            Task {
                try? await Task.sleep(for: .seconds(1), tolerance: .seconds(1))
                await self.evaluateCompletedSession()
            }
        }
    }

    func skipCurrentQuestion() {
        guard var session = currentSession else { return }
        session.skipCurrentQuestion()
        self.currentSession = session
    }

    func abandonCurrentSession() {
        guard var session = currentSession else { return }
        session.status = .abandoned
        self.currentSession = nil
    }

    private func selectQuestionsForQuiz(config: QuizSessionConfig) throws -> [Question] {
        let request: NSFetchRequest<Question> = Question.fetchRequest()

        // Determine which categories to use
        let categoriesToUse: [String] = if let configCategories = config.categories, !configCategories.isEmpty {
            // Use categories from config if provided
            configCategories
        } else {
            // Use enabled categories from settings
            Array(self.settingsService.enabledCategories)
        }

        // Apply category filter using the new category relationship
        if !categoriesToUse.isEmpty {
            request.predicate = NSPredicate(format: "category.name IN %@", categoriesToUse)
            print("🎯 Quiz: Selecting questions from categories: \(categoriesToUse)")
        } else {
            print("⚠️ Quiz: No categories enabled - will select from all questions")
        }

        // Fetch all available questions
        let allQuestions = try context.fetch(request)
        print("🔍 DEBUG: Total questions fetched: \(allQuestions.count)")

        if allQuestions.isEmpty {
            // If no questions found, let's check what's in the database
            let allQuestionsRequest: NSFetchRequest<Question> = Question.fetchRequest()
            let totalQuestions = try context.fetch(allQuestionsRequest)
            print("🔍 DEBUG: Total questions in database: \(totalQuestions.count)")
            let categoryCounts = Dictionary(grouping: totalQuestions, by: { $0.category?.name ?? "nil" })
                .mapValues { $0.count }
            print("🔍 DEBUG: Questions by category: \(categoryCounts)")
        }

        // Filter to available questions (not answered recently or answered incorrectly)
        let availableQuestions = try getAvailableQuestions(from: allQuestions, thresholdHours: 48)

        // If we don't have enough available questions, include some recently answered ones
        let questionsToUse: [Question] = if availableQuestions.count >= config.questionCount {
            availableQuestions
        } else {
            allQuestions
        }

        // Randomly select the required number of questions
        let selectedQuestions = Array(questionsToUse.shuffled().prefix(config.questionCount))

        guard !selectedQuestions.isEmpty else {
            throw QuizSessionError.noQuestionsAvailable
        }

        return selectedQuestions
    }

    private func evaluateCompletedSession() async {
        guard let session = currentSession, session.isCompleted else { return }

        self.isEvaluating = true

        do {
            let result = try await aiService.evaluateQuizSession(session)
            self.lastEvaluationResult = result

            // Save individual results to Core Data
            await self.saveSessionResults(session: session, evaluation: result)
        } catch {
            print("❌ Failed to evaluate quiz session: \(error)")
            // Create a basic evaluation result as fallback
            let fallbackResult = self.createFallbackEvaluation(for: session)
            self.lastEvaluationResult = fallbackResult
        }

        self.isEvaluating = false
    }

    private func saveSessionResults(session: QuizSession, evaluation: QuizEvaluationResult) async {
        for (index, answer) in session.userAnswers.enumerated() {
            guard index < session.questions.count else { continue }

            let question = session.questions[index]
            let questionResult = evaluation.individualResults.first { $0.questionIndex == index }

            // Create or update UserAnswer
            let userAnswer: UserAnswer
            if let existingAnswer = question.userAnswer {
                userAnswer = existingAnswer
            } else {
                userAnswer = UserAnswer(context: self.context)
                userAnswer.question = question
                userAnswer.questionID = question.id
            }

            userAnswer.answer = answer.answer
            userAnswer.timestamp = answer.timestamp
            userAnswer.isCorrect = questionResult?.isCorrect ?? false
        }

        do {
            try self.context.save()
            print("✅ Quiz session results saved to Core Data")
        } catch {
            print("❌ Failed to save quiz session results: \(error)")
        }
    }

    private func createFallbackEvaluation(for session: QuizSession) -> QuizEvaluationResult {
        let correctCount = session.questions.enumerated().compactMap { index, question in
            guard index < session.userAnswers.count,
                  let userAnswer = session.userAnswers[index].answer,
                  let correctAnswer = question.answer else { return nil }

            // Basic string comparison for fallback
            return userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ==
                correctAnswer.lowercased() ? 1 : 0
        }.reduce(0, +)

        let skippedCount = session.userAnswers.filter(\.isSkipped).count
        let overallScore = Double(correctCount) / Double(session.questions.count)

        let individualResults = session.questions.enumerated().map { index, question in
            let answer = index < session.userAnswers.count ? session.userAnswers[index] : nil
            let isCorrect = answer?.answer?.lowercased() == question.answer?.lowercased()

            return QuestionEvaluationResult(
                questionIndex: index,
                isCorrect: isCorrect,
                isSkipped: answer?.isSkipped ?? true,
                feedback: "AI evaluation unavailable. Please try again later.",
                userAnswer: answer?.answer,
                correctAnswer: question.answer ?? ""
            )
        }

        return QuizEvaluationResult(
            sessionId: session.id,
            overallScore: overallScore,
            totalQuestions: session.questions.count,
            correctAnswers: correctCount,
            skippedQuestions: skippedCount,
            individualResults: individualResults,
            insights: ["AI evaluation was unavailable for this session."],
            recommendations: ["Continue practicing to improve your Swift knowledge."],
            strengths: [],
            areasForImprovement: [],
            evaluationTimestamp: Date(),
            categoriesInSession: session.categoriesInSession,
        )
    }

    /// Get available questions using a fetch request instead of filtering in memory
    private func getAvailableQuestions(from allQuestions: [Question],
                                       thresholdHours: TimeInterval) throws -> [Question] {
        let thresholdDate = Date().addingTimeInterval(-thresholdHours * 3600) // Convert hours to seconds

        // Create fetch request for questions that should be retried
        let request: NSFetchRequest<Question> = Question.fetchRequest()

        // Build predicate: questions with no answer OR answered incorrectly/partially OR answered before threshold
        let noAnswerPredicate = NSPredicate(format: "userAnswer == nil")
        let incorrectAnswerPredicate = NSPredicate(format: "userAnswer.isCorrect == false")
        let partialAnswerPredicate = NSPredicate(format: "userAnswer.isPartial == true")
        let oldAnswerPredicate = NSPredicate(format: "userAnswer.timestamp < %@", thresholdDate as NSDate)

        // Combine predicates with OR logic
        let availablePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            noAnswerPredicate,
            incorrectAnswerPredicate,
            partialAnswerPredicate,
            oldAnswerPredicate,
        ])

        // Only include questions from our current set
        let questionIds = allQuestions.compactMap(\.id)
        let inSetPredicate = NSPredicate(format: "id IN %@", questionIds)

        // Combine with AND logic
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            availablePredicate,
            inSetPredicate,
        ])

        do {
            let fetchedQuestions = try self.context.fetch(request)
            print("🔍 DEBUG: Fetched \(fetchedQuestions.count) available questions out of \(allQuestions.count) total")
            return fetchedQuestions
        } catch {
            print("❌ Failed to fetch available questions: \(error)")
            // Fallback to filtering in memory
            return allQuestions.filter { question in
                question.shouldRetry(thresholdHours: thresholdHours)
            }
        }
    }
}
