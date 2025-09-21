//
//  DailyRegimenService.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/18/25.
//

import Combine
import Foundation

@MainActor
final class DailyRegimenService: ObservableObject {
    static let shared = DailyRegimenService(notificationService: NotificationService.shared)

    // MARK: - Published Properties

    @Published var currentRegimen: DailyRegimen?
    @Published var todaysSession: DailySession?
    @Published var recentSessions: [DailySession] = []
    @Published var studyStreak: StudyStreak = .init()
    @Published var insights: [StudyInsight] = []
    @Published var recommendations: [StudyRecommendation] = []

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let notificationService: NotificationService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UserDefaults Keys

    private let regimenKey = "daily_regimen"
    private let sessionsKey = "daily_sessions"
    private let streakKey = "study_streak"
    private let insightsKey = "study_insights"
    private let recommendationsKey = "study_recommendations"

    private init(notificationService: NotificationService) {
        self.notificationService = notificationService
        self.loadData()
        self.setupDailyCheck()
    }

    // MARK: - Public Methods

    /// Enable daily regimen with specified configuration
    func enableRegimen(goal: DailyGoal, reminderTime: Date? = nil) {
        var regimen = DailyRegimen(dailyGoal: goal)

        if let reminderTime {
            regimen.reminderSettings.preferredTime = reminderTime
        }

        self.currentRegimen = regimen
        self.saveRegimen()

        // Schedule notifications
        if regimen.reminderSettings.isEnabled {
            self.scheduleReminders(for: regimen)
        }

        print("📅 Daily Regimen: Enabled with goal: \(goal.displayText)")
    }

    /// Disable daily regimen
    func disableRegimen() {
        self.currentRegimen?.isEnabled = false
        self.saveRegimen()
        self.cancelAllReminders()
        print("📅 Daily Regimen: Disabled")
    }

    /// Update regimen configuration
    func updateRegimen(_ regimen: DailyRegimen) {
        self.currentRegimen = regimen
        self.saveRegimen()

        if regimen.reminderSettings.isEnabled {
            self.scheduleReminders(for: regimen)
        } else {
            self.cancelAllReminders()
        }
    }

    /// Record progress from a completed quiz session
    func recordProgress(from quizSession: QuizSession, evaluation: QuizEvaluationResult) {
        guard let regimen = currentRegimen, regimen.isEnabled else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let sessionDate = Calendar.current.startOfDay(for: quizSession.startTime)

        // Only record progress for today's sessions
        guard sessionDate == today else { return }

        self.updateTodaysSession(with: quizSession, evaluation: evaluation)
        self.checkGoalCompletion()
        self.generateInsights()
        self.saveData()

        print("📅 Daily Regimen: Recorded progress - \(quizSession.questions.count) questions")
    }

    /// Get today's progress toward goal
    func getTodaysProgress() -> DailyProgress {
        guard let regimen = currentRegimen,
              let session = todaysSession else {
            return DailyProgress(current: 0, target: self.currentRegimen?.dailyGoal.targetValue ?? 5)
        }

        let target = regimen.dailyGoal.targetValue
        let current: Int = switch regimen.dailyGoal {
        case .questionCount:
            session.questionsCompleted
        case .timeBasedMinutes:
            Int(session.timeSpent / 60)
        case .categoryFocus:
            session.questionsCompleted
        }

        return DailyProgress(current: current, target: target)
    }

    /// Check if today's goal has been achieved
    func isTodaysGoalAchieved() -> Bool {
        self.getTodaysProgress().isCompleted
    }

    /// Get streak recovery status
    func getStreakRecoveryStatus() -> (canRecover: Bool, daysToRecover: Int) {
        let canRecover = self.studyStreak.shouldOfferStreakRecovery()
        let daysToRecover = canRecover ? 3 : 0
        return (canRecover, daysToRecover)
    }

    // MARK: - Private Methods

    private func loadData() {
        // Load regimen
        if let regimenData = userDefaults.data(forKey: regimenKey),
           let regimen = try? JSONDecoder().decode(DailyRegimen.self, from: regimenData) {
            self.currentRegimen = regimen
        }

        // Load recent sessions
        if let sessionsData = userDefaults.data(forKey: sessionsKey),
           let sessions = try? JSONDecoder().decode([DailySession].self, from: sessionsData) {
            self.recentSessions = sessions
            self.updateTodaysSessionFromRecent()
        }

        // Load streak
        if let streakData = userDefaults.data(forKey: streakKey),
           let streak = try? JSONDecoder().decode(StudyStreak.self, from: streakData) {
            self.studyStreak = streak
        }

        // Load insights
        if let insightsData = userDefaults.data(forKey: insightsKey),
           let loadedInsights = try? JSONDecoder().decode([StudyInsight].self, from: insightsData) {
            self.insights = loadedInsights
        }

        // Load recommendations
        if let recommendationsData = userDefaults.data(forKey: recommendationsKey),
           let loadedRecommendations = try? JSONDecoder()
           .decode([StudyRecommendation].self, from: recommendationsData) {
            self.recommendations = loadedRecommendations
        }
    }

    private func saveData() {
        self.saveRegimen()
        self.saveSessions()
        self.saveStreak()
        self.saveInsights()
        self.saveRecommendations()
    }

    private func saveRegimen() {
        guard let regimen = currentRegimen,
              let data = try? JSONEncoder().encode(regimen) else { return }
        self.userDefaults.set(data, forKey: self.regimenKey)
    }

    private func saveSessions() {
        guard let data = try? JSONEncoder().encode(recentSessions) else { return }
        self.userDefaults.set(data, forKey: self.sessionsKey)
    }

    private func saveStreak() {
        guard let data = try? JSONEncoder().encode(studyStreak) else { return }
        self.userDefaults.set(data, forKey: self.streakKey)
    }

    private func saveInsights() {
        guard let data = try? JSONEncoder().encode(insights) else { return }
        self.userDefaults.set(data, forKey: self.insightsKey)
    }

    private func saveRecommendations() {
        guard let data = try? JSONEncoder().encode(recommendations) else { return }
        self.userDefaults.set(data, forKey: self.recommendationsKey)
    }

    private func updateTodaysSessionFromRecent() {
        let today = Calendar.current.startOfDay(for: Date())
        self.todaysSession = self.recentSessions.first { session in
            Calendar.current.startOfDay(for: session.date) == today
        }
    }

    private func updateTodaysSession(with quizSession: QuizSession, evaluation: QuizEvaluationResult) {
        let today = Calendar.current.startOfDay(for: Date())

        if self.todaysSession == nil {
            // Create new session for today
            self.todaysSession = DailySession(
                date: today,
                questionsCompleted: 0,
                timeSpent: 0,
                categoriesStudied: [],
                averageScore: 0.0,
                goalAchieved: false,
                streakDay: self.studyStreak.currentStreak,
                quizSessionIds: [],
                correctAnswers: 0,
                totalQuestions: 0,
                improvementAreas: []
            )
        }

        guard var session = todaysSession else { return }

        // Update session with new quiz data
        let sessionDuration = quizSession.duration ?? 0
        let newQuestionsCompleted = session.questionsCompleted + quizSession.questions.count
        let newTimeSpent = session.timeSpent + sessionDuration
        let newCorrectAnswers = session.correctAnswers + evaluation.correctAnswers
        let newTotalQuestions = session.totalQuestions + evaluation.totalQuestions

        // Merge categories
        let newCategories = Set(session.categoriesStudied).union(Set(evaluation.categoriesInSession))

        // Calculate weighted average score
        let totalPreviousScore = session.averageScore * Double(session.totalQuestions)
        let newSessionScore = evaluation.overallScore * Double(evaluation.totalQuestions)
        let newAverageScore = newTotalQuestions > 0 ?
            (totalPreviousScore + newSessionScore) / Double(newTotalQuestions) : 0.0

        // Identify improvement areas
        let newImprovementAreas = evaluation.areasForImprovement

        session = DailySession(
            date: session.date,
            questionsCompleted: newQuestionsCompleted,
            timeSpent: newTimeSpent,
            categoriesStudied: Array(newCategories),
            averageScore: newAverageScore,
            goalAchieved: session.goalAchieved, // Will be updated in checkGoalCompletion
            streakDay: session.streakDay,
            quizSessionIds: session.quizSessionIds + [quizSession.id],
            correctAnswers: newCorrectAnswers,
            totalQuestions: newTotalQuestions,
            improvementAreas: newImprovementAreas
        )

        self.todaysSession = session
        self.updateRecentSessions(with: session)
    }

    private func updateRecentSessions(with session: DailySession) {
        let today = Calendar.current.startOfDay(for: Date())

        // Remove existing session for today and add updated one
        self.recentSessions.removeAll { existingSession in
            Calendar.current.startOfDay(for: existingSession.date) == today
        }

        self.recentSessions.insert(session, at: 0)

        // Keep only last 30 days
        self.recentSessions = Array(self.recentSessions.prefix(30))
    }

    private func checkGoalCompletion() {
        guard var session = todaysSession else { return }

        let wasGoalAchieved = session.goalAchieved
        let isGoalAchieved = self.isTodaysGoalAchieved()

        if !wasGoalAchieved, isGoalAchieved {
            // Goal just achieved!
            session.goalAchieved = true
            self.todaysSession = session

            // Update streak
            self.studyStreak.updateStreak(for: Date(), goalAchieved: true)

            // Update regimen streak counters
            self.currentRegimen?.currentStreak = self.studyStreak.currentStreak
            self.currentRegimen?.longestStreak = self.studyStreak.longestStreak
            self.currentRegimen?.lastCompletedDate = Date()

            // Create celebration insight
            if self.studyStreak.currentStreak > 1 {
                let insight = StudyInsight(
                    type: .streakMilestone,
                    title: "🔥 Streak Continues!",
                    description: "You've maintained your study streak for \(studyStreak.currentStreak) days!"
                )
                self.insights.insert(insight, at: 0)
            }

            print("🎉 Daily Regimen: Goal achieved! Streak: \(self.studyStreak.currentStreak)")
        }
    }

    private func generateInsights() {
        // Generate insights based on recent performance
        // This is a simplified version - could be much more sophisticated

        guard self.recentSessions.count >= 3 else { return }

        let recentPerformance = self.recentSessions.prefix(7)
        let averageAccuracy = recentPerformance.map(\.accuracy).reduce(0, +) / Double(recentPerformance.count)

        // Performance trend insight
        if averageAccuracy > 0.8 {
            let insight = StudyInsight(
                type: .categoryImprovement,
                title: "📈 Strong Performance",
                description: "Your accuracy has been consistently above 80% this week!"
            )

            // Only add if we don't already have a similar recent insight
            if !self.insights
                .contains(where: {
                    $0.type == .categoryImprovement && $0.createdDate > Date().addingTimeInterval(-86400 * 3)
                }) {
                self.insights.insert(insight, at: 0)
            }
        }

        // Keep only recent insights (last 14 days)
        let cutoffDate = Date().addingTimeInterval(-86400 * 14)
        self.insights.removeAll { $0.createdDate < cutoffDate }
    }

    private func setupDailyCheck() {
        // Check daily at midnight for streak management and session reset
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task { @MainActor in
                self.performDailyCheck()
            }
        }
    }

    private func performDailyCheck() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        // Check if we missed yesterday's goal
        let yesterdaysSession = self.recentSessions.first { session in
            Calendar.current.startOfDay(for: session.date) == yesterday
        }

        if yesterdaysSession?.goalAchieved != true {
            // Missed yesterday - check if streak should be broken
            if !self.studyStreak.isStreakActive() {
                self.studyStreak.currentStreak = 0
                self.currentRegimen?.currentStreak = 0
            }
        }

        // Reset today's session if needed
        if self.todaysSession?.date != today {
            self.todaysSession = nil
        }
    }

    private func scheduleReminders(for regimen: DailyRegimen) {
        guard regimen.reminderSettings.isEnabled else { return }

        Task {
            await self.notificationService.scheduleDailyRegimenReminder(
                at: regimen.reminderSettings.preferredTime,
                goal: regimen.dailyGoal
            )
        }
    }

    private func cancelAllReminders() {
        Task {
            await self.notificationService.cancelDailyRegimenReminders()
        }
    }
}
