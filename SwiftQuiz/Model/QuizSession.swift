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

enum PerformanceLevel: String, Codable, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case needsImprovement = "Needs Improvement"
    case poor = "Poor"

    var emoji: String {
        switch self {
        case .excellent: "🌟"
        case .good: "👍"
        case .fair: "👌"
        case .needsImprovement: "📈"
        case .poor: "📚"
        }
    }

    var color: String {
        switch self {
        case .excellent: "green"
        case .good: "blue"
        case .fair: "orange"
        case .needsImprovement: "yellow"
        case .poor: "red"
        }
    }
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
