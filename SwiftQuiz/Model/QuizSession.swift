//
//  QuizSession.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/17/25.
//

import Foundation

struct QuizAnswer: Identifiable {
    let id = UUID()
    let questionIndex: Int
    let answer: String?
    let timestamp: Date

    var isSkipped: Bool {
        self.answer == nil
    }
}

enum QuizSessionStatus: String, Codable, CaseIterable {
    case inProgress = "in_progress"
    case completed
    case abandoned
}

// MARK: - Quiz Session Configuration

struct QuizSessionConfig {
    static let defaultQuestionCount = 5
    static let maxQuestionCount = 10
    static let minQuestionCount = 1

    let questionCount: Int
    let timeLimit: TimeInterval?
    let categories: [String]?

    init(questionCount: Int = defaultQuestionCount,
         timeLimit: TimeInterval? = nil,
         categories: [String]? = nil) {
        self.questionCount = max(
            Self.minQuestionCount,
            min(Self.maxQuestionCount, questionCount)
        )
        self.timeLimit = timeLimit
        self.categories = categories
    }
}

// MARK: - Quiz Evaluation Result

struct QuizEvaluationResult: Codable {
    let sessionId: UUID
    let overallScore: Double // 0.0 to 1.0
    let totalQuestions: Int
    let correctAnswers: Int
    let skippedQuestions: Int
    let individualResults: [QuestionEvaluationResult]
    let insights: [String]
    let recommendations: [String]
    let strengths: [String]
    let areasForImprovement: [String]
    let evaluationTimestamp: Date
    let categoriesInSession: [String]
    let categoryPerformance: [String: CategoryPerformance]

    init(sessionId: UUID, overallScore: Double, totalQuestions: Int, correctAnswers: Int,
         skippedQuestions: Int, individualResults: [QuestionEvaluationResult], insights: [String],
         recommendations: [String], strengths: [String], areasForImprovement: [String],
         evaluationTimestamp: Date, categoriesInSession: [String] = [],
         categoryPerformance: [String: CategoryPerformance] = [:]) {
        self.sessionId = sessionId
        self.overallScore = overallScore
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
        self.skippedQuestions = skippedQuestions
        self.individualResults = individualResults
        self.insights = insights
        self.recommendations = recommendations
        self.strengths = strengths
        self.areasForImprovement = areasForImprovement
        self.evaluationTimestamp = evaluationTimestamp
        self.categoriesInSession = categoriesInSession
        self.categoryPerformance = categoryPerformance
    }

    var scorePercentage: Int {
        Int(self.overallScore * 100)
    }

    var performanceLevel: PerformanceLevel {
        switch self.overallScore {
        case 0.9...1.0:
            .excellent
        case 0.8..<0.9:
            .good
        case 0.6..<0.8:
            .fair
        case 0.4..<0.6:
            .needsImprovement
        default:
            .poor
        }
    }
}

struct QuestionEvaluationResult: Identifiable, Codable {
    let id = UUID()
    let questionIndex: Int
    let isCorrect: Bool
    let isSkipped: Bool
    let feedback: String
    let userAnswer: String?
    let correctAnswer: String
}

struct QuizSession: Identifiable {
    let id = UUID()
    let questions: [Question]
    let startTime: Date
    var endTime: Date?
    var userAnswers: [QuizAnswer]
    var status: QuizSessionStatus

    init(questions: [Question]) {
        self.questions = questions
        self.startTime = Date()
        self.userAnswers = []
        self.status = .inProgress
    }

    // Analytics properties
    var categoriesInSession: [String] {
        Array(Set(self.questions.compactMap(\.category))).sorted()
    }

    var categoryBreakdown: [String: Int] {
        var breakdown: [String: Int] = [:]
        for question in self.questions {
            let category = question.category ?? "Unknown"
            breakdown[category, default: 0] += 1
        }
        return breakdown
    }

    var duration: TimeInterval? {
        guard let endTime else { return nil }
        return endTime.timeIntervalSince(self.startTime)
    }

    var isCompleted: Bool {
        self.status == .completed
    }

    var currentQuestionIndex: Int {
        self.userAnswers.count
    }

    var currentQuestion: Question? {
        guard self.currentQuestionIndex < self.questions.count else { return nil }
        return self.questions[self.currentQuestionIndex]
    }

    var progress: Double {
        guard !self.questions.isEmpty else { return 0 }
        return Double(self.userAnswers.count) / Double(self.questions.count)
    }

    mutating func addAnswer(_ answer: String, for questionIndex: Int) {
        guard questionIndex == self.currentQuestionIndex,
              questionIndex < self.questions.count else { return }

        let quizAnswer = QuizAnswer(
            questionIndex: questionIndex,
            answer: answer,
            timestamp: Date()
        )
        self.userAnswers.append(quizAnswer)

        // Check if session is complete
        if self.userAnswers.count == self.questions.count {
            self.complete()
        }
    }

    mutating func skipCurrentQuestion() {
        guard self.currentQuestionIndex < self.questions.count else { return }

        let quizAnswer = QuizAnswer(
            questionIndex: currentQuestionIndex,
            answer: nil,
            timestamp: Date()
        )
        self.userAnswers.append(quizAnswer)

        // Check if session is complete
        if self.userAnswers.count == self.questions.count {
            self.complete()
        }
    }

    private mutating func complete() {
        self.endTime = Date()
        self.status = .completed
    }
}
