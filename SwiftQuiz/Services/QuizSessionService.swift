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

    @Published var currentSession: QuizSession?
    @Published var lastEvaluationResult: QuizEvaluationResult?
    @Published var isEvaluating = false

    init(context: NSManagedObjectContext, aiService: AIService = .shared) {
        self.context = context
        self.aiService = aiService
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

        if session.isCompleted {
            Task {
                await self.evaluateCompletedSession()
            }
        }
    }

    func skipCurrentQuestion() {
        guard var session = currentSession else { return }
        session.skipCurrentQuestion()
        self.currentSession = session

        if session.isCompleted {
            Task {
                await self.evaluateCompletedSession()
            }
        }
    }

    func abandonCurrentSession() {
        guard var session = currentSession else { return }
        session.status = .abandoned
        self.currentSession = nil
    }

    private func selectQuestionsForQuiz(config: QuizSessionConfig) throws -> [Question] {
        let request: NSFetchRequest<Question> = Question.fetchRequest()

        // Apply category filter if specified
        if let categories = config.categories, !categories.isEmpty {
            request.predicate = NSPredicate(format: "primaryTag IN %@", categories)
        }

        // Fetch all available questions
        let allQuestions = try context.fetch(request)

        // Filter to available questions (not answered recently or answered incorrectly)
        let availableQuestions = allQuestions.filter { question in
            guard let userAnswer = question.userAnswer else { return true }
            return userAnswer.shouldRetry(thresholdHours: 48)
        }

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
            self.lastEvaluationResult = self.createFallbackEvaluation(for: session)
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
            userAnswer.interactionTypeEnum = answer.isSkipped ? .skipped : .answered
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
            evaluationTimestamp: Date()
        )
    }
}
