//
//  LearningAnalyticsService.swift
//  SwiftQuiz
//
//  Created by Claude on 12/20/24.
//

import CoreData
import Foundation

// MARK: - Enums

enum ProficiencyStatus: String, CaseIterable {
    case notStarted = "not_started"
    case struggling
    case developing
    case proficient
    case expert

    var displayName: String {
        switch self {
        case .notStarted: "Not Started"
        case .struggling: "Struggling"
        case .developing: "Developing"
        case .proficient: "Proficient"
        case .expert: "Expert"
        }
    }

    var color: String {
        switch self {
        case .notStarted: "#8E8E93"
        case .struggling: "#FF3B30"
        case .developing: "#FF9500"
        case .proficient: "#007AFF"
        case .expert: "#34C759"
        }
    }
}

enum InsightType {
    case strength, weakness, improvement, recommendation
}

enum InsightPriority {
    case low, medium, high, critical
}

enum RecommendationType {
    case review, practice, learn, reinforce
}

// MARK: - Structs

struct StudyStreakData {
    let currentStreak: Int
    let longestStreak: Int
    let lastStudyDate: Date?
}

struct TopicProficiency {
    let topic: Topic
    let proficiencyLevel: Double // 0.0 to 1.0
    let questionsAttempted: Int
    let correctAnswers: Int
    let averageTime: TimeInterval
    let lastAttempt: Date?
    let needsReview: Bool

    var accuracy: Double {
        self.questionsAttempted > 0 ? Double(self.correctAnswers) / Double(self.questionsAttempted) : 0.0
    }

    var proficiencyStatus: ProficiencyStatus {
        switch self.proficiencyLevel {
        case 0.9...1.0: .expert
        case 0.7..<0.9: .proficient
        case 0.5..<0.7: .developing
        case 0.2..<0.5: .struggling
        default: .notStarted
        }
    }
}

struct AnalyticsCategoryPerformance {
    let category: Category
    let topicProficiencies: [TopicProficiency]
    let overallProficiency: Double
    let questionsAttempted: Int
    let correctAnswers: Int
    let averageTime: TimeInterval
    let lastActivity: Date?

    var accuracy: Double {
        self.questionsAttempted > 0 ? Double(self.correctAnswers) / Double(self.questionsAttempted) : 0.0
    }

    var weakestTopics: [TopicProficiency] {
        Array(
            self.topicProficiencies
                .filter { $0.questionsAttempted > 0 }
                .sorted { $0.proficiencyLevel < $1.proficiencyLevel }
                .prefix(3)
        )
    }

    var strongestTopics: [TopicProficiency] {
        Array(
            self.topicProficiencies
                .filter { $0.questionsAttempted > 0 }
                .sorted { $0.proficiencyLevel > $1.proficiencyLevel }
                .prefix(3)
        )
    }
}

struct AnalyticsInsight {
    let type: InsightType
    let title: String
    let description: String
    let priority: InsightPriority
    let actionable: Bool
    let relatedTopics: [Topic]
}

struct LearningRecommendation {
    let type: RecommendationType
    let title: String
    let description: String
    let targetTopics: [Topic]
    let estimatedTime: TimeInterval
    let resources: [LearningResource]
}

// MARK: - Classes

final class LearningAnalyticsService: ObservableObject {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Topic Analytics

    func calculateTopicProficiency(for topic: Topic) throws -> TopicProficiency {
        let questions = try fetchQuestions(for: topic)
        let userAnswers = try fetchUserAnswers(for: questions)

        let questionsAttempted = Set(userAnswers.compactMap(\.questionID)).count
        let correctAnswers = userAnswers.filter(\.isCorrect).count
        let totalTime = userAnswers.reduce(0) { $0 + TimeInterval($1.timeSpent) }
        let averageTime = questionsAttempted > 0 ? totalTime / Double(questionsAttempted) : 0
        let lastAttempt = userAnswers.max(by: { $0.timestamp! < $1.timestamp! })?.timestamp

        // Calculate mastery level using multiple factors
        let accuracy = questionsAttempted > 0 ? Double(correctAnswers) / Double(questionsAttempted) : 0.0
        let completionRatio = Double(questionsAttempted) / Double(questions.count)
        let recencyFactor = self.calculateRecencyFactor(lastAttempt: lastAttempt)

        let proficiencyLevel = (accuracy * 0.6) + (completionRatio * 0.3) + (recencyFactor * 0.1)

        // Determine if topic needs review based on spaced repetition
        let needsReview = self.shouldReviewTopic(userAnswers: userAnswers, accuracy: accuracy)

        return TopicProficiency(
            topic: topic,
            proficiencyLevel: min(1.0, proficiencyLevel),
            questionsAttempted: questionsAttempted,
            correctAnswers: correctAnswers,
            averageTime: averageTime,
            lastAttempt: lastAttempt,
            needsReview: needsReview
        )
    }

    func calculateAllTopicProficiencies(for subject: Subject) throws -> [TopicProficiency] {
        let topics = try fetchTopics(for: subject)

        return try topics.map { topic in
            try self.calculateTopicProficiency(for: topic)
        }
    }

    // MARK: - Category Analytics

    func calculateCategoryPerformance(for category: Category) throws -> AnalyticsCategoryPerformance {
        let topics = Array(category.topics as? Set<Topic> ?? [])
        let topicProficiencies = try topics.map { try self.calculateTopicProficiency(for: $0) }

        let totalQuestionsAttempted = topicProficiencies.reduce(0) { $0 + $1.questionsAttempted }
        let totalCorrectAnswers = topicProficiencies.reduce(0) { $0 + $1.correctAnswers }
        let totalTime = topicProficiencies.reduce(0) { $0 + $1.averageTime }
        let averageTime = totalTime / Double(max(topicProficiencies.count, 1))
        let lastActivity = topicProficiencies.compactMap(\.lastAttempt).max()

        let totalProficiency = topicProficiencies.reduce(0) { $0 + $1.proficiencyLevel }
        let overallProficiency = totalProficiency / Double(max(topicProficiencies.count, 1))

        return AnalyticsCategoryPerformance(
            category: category,
            topicProficiencies: topicProficiencies,
            overallProficiency: overallProficiency,
            questionsAttempted: totalQuestionsAttempted,
            correctAnswers: totalCorrectAnswers,
            averageTime: averageTime,
            lastActivity: lastActivity
        )
    }

    func calculateAllCategoryPerformances(for subject: Subject) throws -> [AnalyticsCategoryPerformance] {
        let categories = try fetchCategories(for: subject)

        return try categories.map { category in
            try self.calculateCategoryPerformance(for: category)
        }
    }

    // MARK: - Study Insights

    func generateStudyInsights(for subject: Subject) throws -> [AnalyticsInsight] {
        let categoryPerformances = try calculateAllCategoryPerformances(for: subject)
        var insights: [AnalyticsInsight] = []

        // Identify strengths
        let strongCategories = categoryPerformances
            .filter { $0.overallProficiency >= 0.8 && $0.questionsAttempted >= 3 }
            .sorted { $0.overallProficiency > $1.overallProficiency }

        if let strongest = strongCategories.first {
            insights.append(AnalyticsInsight(
                type: .strength,
                title: "Strong in \(strongest.category.name ?? "Unknown")",
                description: "You've completed \(Int(strongest.overallProficiency * 100))% of topics in this category",
                priority: .medium,
                actionable: false,
                relatedTopics: strongest.topicProficiencies.map(\.topic)
            ))
        }

        // Identify weaknesses
        let weakCategories = categoryPerformances
            .filter { $0.overallProficiency < 0.5 && $0.questionsAttempted >= 2 }
            .sorted { $0.overallProficiency < $1.overallProficiency }

        if let weakest = weakCategories.first {
            insights.append(AnalyticsInsight(
                type: .weakness,
                title: "Focus on \(weakest.category.name ?? "Unknown")",
                description: "This category needs attention - only " +
                    "\(Int(weakest.overallProficiency * 100))% proficiency",
                priority: .high,
                actionable: true,
                relatedTopics: weakest.weakestTopics.map(\.topic)
            ))
        }

        // Identify topics that need review
        let allTopics = categoryPerformances.flatMap(\.topicProficiencies)
        let topicsNeedingReview = allTopics.filter(\.needsReview)

        if !topicsNeedingReview.isEmpty {
            insights.append(AnalyticsInsight(
                type: .recommendation,
                title: "Review Time",
                description: "\(topicsNeedingReview.count) topics are ready for review to maintain proficiency",
                priority: .medium,
                actionable: true,
                relatedTopics: topicsNeedingReview.map(\.topic)
            ))
        }

        return insights
    }

    // MARK: - Learning Recommendations

    func generateLearningRecommendations(for subject: Subject) throws -> [LearningRecommendation] {
        let categoryPerformances = try calculateAllCategoryPerformances(for: subject)
        var recommendations: [LearningRecommendation] = []

        // Recommend practice for struggling topics
        let allTopicProficiencies = categoryPerformances.flatMap(\.topicProficiencies)
        let strugglingAndDeveloping = allTopicProficiencies.filter {
            $0.proficiencyStatus == .struggling || $0.proficiencyStatus == .developing
        }
        let sortedByProficiency = strugglingAndDeveloping.sorted { $0.proficiencyLevel < $1.proficiencyLevel }
        let strugglingTopics = Array(sortedByProficiency.prefix(3))

        for topicProficiency in strugglingTopics {
            let resources = try fetchLearningResources(for: topicProficiency.topic)

            recommendations.append(LearningRecommendation(
                type: .practice,
                title: "Practice \(topicProficiency.topic.name ?? "Unknown")",
                description: "Your proficiency is at \(Int(topicProficiency.proficiencyLevel * 100))%. " +
                    "Practice more questions to improve.",
                targetTopics: [topicProficiency.topic],
                estimatedTime: TimeInterval(topicProficiency.topic.estimatedTime * 60),
                resources: resources
            ))
        }

        // Recommend new topics based on prerequisites
        let allProficiencies = categoryPerformances.flatMap(\.topicProficiencies)
        let expertLevelTopics = allProficiencies.filter { $0.proficiencyStatus == .expert }
        let completedTopics = expertLevelTopics.map(\.topic)

        let availableTopics = try fetchTopics(for: subject)
        let attemptedTopicIds = Set(allProficiencies
            .filter { $0.questionsAttempted > 0 }
            .compactMap(\.topic.id)
        )
        let untriedTopics = availableTopics.filter { topic in
            !(attemptedTopicIds.contains(topic.id ?? ""))
        }

        for topic in untriedTopics.prefix(2) {
            let prerequisites = Array(topic.prerequisites as? Set<Topic> ?? [])
            let prerequisitesMet = prerequisites.allSatisfy { prereq in
                completedTopics.contains { $0.id == prereq.id }
            }

            if prerequisitesMet {
                let resources = try fetchLearningResources(for: topic)

                recommendations.append(LearningRecommendation(
                    type: .learn,
                    title: "Learn \(topic.name ?? "Unknown")",
                    description: "You're ready to learn this topic based on your current progress.",
                    targetTopics: [topic],
                    estimatedTime: TimeInterval(topic.estimatedTime * 60),
                    resources: resources
                ))
            }
        }

        return recommendations
    }

    // MARK: - Study Streak Analytics

    func calculateStudyStreak() throws -> StudyStreakData {
        let request: NSFetchRequest<UserAnswer> = UserAnswer.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserAnswer.timestamp, ascending: false)]

        let userAnswers = try context.fetch(request)

        guard !userAnswers.isEmpty else {
            return StudyStreakData(currentStreak: 0, longestStreak: 0, lastStudyDate: nil)
        }

        let lastStudyDate = userAnswers.first?.timestamp

        // Group answers by day
        let calendar = Calendar.current
        let answersByDay = Dictionary(grouping: userAnswers) { answer in
            calendar.startOfDay(for: answer.timestamp ?? Date())
        }

        let studyDays = Array(answersByDay.keys).sorted(by: >)

        // Calculate current streak
        var currentStreak = 0
        let today = calendar.startOfDay(for: Date())

        for day in studyDays {
            let daysDifference = calendar.dateComponents([.day], from: day, to: today).day ?? 0

            if daysDifference == currentStreak {
                currentStreak += 1
            } else {
                break
            }
        }

        // Calculate longest streak
        var longestStreak = 0
        var tempStreak = 0
        var previousDay: Date?

        for day in studyDays.reversed() {
            if let prev = previousDay {
                let daysBetween = calendar.dateComponents([.day], from: prev, to: day).day ?? 0
                if daysBetween == 1 {
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }
            previousDay = day
        }
        longestStreak = max(longestStreak, tempStreak)

        return StudyStreakData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastStudyDate: lastStudyDate
        )
    }

    // MARK: - Private Helper Methods

    private func fetchQuestions(for topic: Topic) throws -> [Question] {
        let request: NSFetchRequest<Question> = Question.fetchRequest()
        request.predicate = NSPredicate(format: "ANY topics == %@", topic)
        return try self.context.fetch(request)
    }

    private func fetchUserAnswers(for questions: [Question]) throws -> [UserAnswer] {
        guard !questions.isEmpty else { return [] }

        let questionIds = questions.compactMap(\.id)
        let request: NSFetchRequest<UserAnswer> = UserAnswer.fetchRequest()
        request.predicate = NSPredicate(format: "questionID IN %@", questionIds)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserAnswer.timestamp, ascending: false)]

        return try self.context.fetch(request)
    }

    private func fetchTopics(for subject: Subject) throws -> [Topic] {
        let request: NSFetchRequest<Topic> = Topic.fetchRequest()
        request.predicate = NSPredicate(format: "ANY categories.subject == %@", subject)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Topic.sortOrder, ascending: true)]
        return try self.context.fetch(request)
    }

    private func fetchCategories(for subject: Subject) throws -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "subject == %@", subject)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)]
        return try self.context.fetch(request)
    }

    private func fetchLearningResources(for topic: Topic) throws -> [LearningResource] {
        let request: NSFetchRequest<LearningResource> = LearningResource.fetchRequest()
        request.predicate = NSPredicate(format: "topic == %@", topic)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LearningResource.isOfficial, ascending: false)]
        return try self.context.fetch(request)
    }

    private func calculateRecencyFactor(lastAttempt: Date?) -> Double {
        guard let lastAttempt else { return 0.0 }

        let daysSinceLastAttempt = Date().timeIntervalSince(lastAttempt) / (24 * 60 * 60)

        // Decay factor: recent attempts have higher value
        switch daysSinceLastAttempt {
        case 0...1: return 1.0
        case 1...3: return 0.8
        case 3...7: return 0.6
        case 7...14: return 0.4
        case 14...30: return 0.2
        default: return 0.1
        }
    }

    private func shouldReviewTopic(userAnswers: [UserAnswer], accuracy: Double) -> Bool {
        // Simple spaced repetition logic
        guard !userAnswers.isEmpty else { return false }

        let lastAnswer = userAnswers.max(by: { $0.timestamp! < $1.timestamp! })
        let daysSinceLastAttempt = Date().timeIntervalSince(lastAnswer?.timestamp ?? Date()) / (24 * 60 * 60)

        // Review if accuracy is low or it's been a while
        return accuracy < 0.7 || daysSinceLastAttempt > 7
    }
}
