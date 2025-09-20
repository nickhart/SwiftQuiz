//
//  TaxonomyImportService.swift
//  SwiftQuiz
//
//  Created by Claude on 12/20/24.
//

import CoreData
import Foundation

struct TaxonomyData: Codable {
    let subject: SubjectData
    let versions: [SubjectVersionData]
    let categories: [CategoryData]
    let topics: [TopicData]
    let learningResources: [LearningResourceData]
}

struct SubjectData: Codable {
    let id: String
    let name: String
    let displayName: String?
    let description: String?
    let iconName: String?
    let color: String?
    let isActive: Bool
    let currentVersion: String?
}

struct SubjectVersionData: Codable {
    let id: String
    let version: String
    let name: String
    let releaseDate: String?
    let isLatest: Bool
    let isSupported: Bool
    let changelog: String?
}

struct CategoryData: Codable {
    let id: String
    let name: String
    let description: String?
    let sortOrder: Int
    let iconName: String?
    let color: String?
    let isCore: Bool
}

struct TopicData: Codable {
    let id: String
    let name: String
    let description: String?
    let categories: [String]
    let difficulty: Int
    let estimatedTime: Int
    let isCore: Bool
    let prerequisites: [String]
    let sortOrder: Int
}

struct LearningResourceData: Codable {
    let id: String
    let title: String
    let description: String?
    let url: String
    let type: String
    let difficulty: Int
    let estimatedTime: Int
    let isOfficial: Bool
    let language: String?
    let topics: [String]
}

@MainActor
final class TaxonomyImportService: ObservableObject {
    enum ImportError: LocalizedError {
        case fileNotFound(String)
        case invalidFormat(String)
        case coreDataError(Error)

        var errorDescription: String? {
            switch self {
            case let .fileNotFound(filename):
                "Taxonomy file '\(filename)' not found"
            case let .invalidFormat(reason):
                "Invalid taxonomy format: \(reason)"
            case let .coreDataError(error):
                "Core Data error: \(error.localizedDescription)"
            }
        }
    }

    private let context: NSManagedObjectContext
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func importTaxonomy(from filename: String) async throws {
        print("Starting taxonomy import from \(filename)")

        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw ImportError.fileNotFound("\(filename).json")
        }

        let data = try Data(contentsOf: url)
        let taxonomyData = try JSONDecoder().decode(TaxonomyData.self, from: data)

        try await withCheckedThrowingContinuation { continuation in
            self.context.perform {
                do {
                    try self.importSubject(taxonomyData.subject)
                    try self.importVersions(taxonomyData.versions, for: taxonomyData.subject.id)
                    try self.importCategories(taxonomyData.categories, for: taxonomyData.subject.id)
                    try self.importTopics(taxonomyData.topics, categories: taxonomyData.categories)
                    try self.importLearningResources(taxonomyData.learningResources)

                    try self.context.save()
                    print("Successfully imported taxonomy for subject: \(taxonomyData.subject.name)")
                    continuation.resume()
                } catch {
                    print("Error importing taxonomy: \(error)")
                    continuation.resume(throwing: ImportError.coreDataError(error))
                }
            }
        }
    }

    private func importSubject(_ subjectData: SubjectData) throws {
        let existingSubject = try fetchExistingSubject(id: subjectData.id)
        let subject = existingSubject ?? Subject(context: self.context)

        subject.id = subjectData.id
        subject.name = subjectData.name
        subject.displayName = subjectData.displayName
        subject.subjectDescription = subjectData.description
        subject.iconName = subjectData.iconName
        subject.color = subjectData.color
        subject.isActive = subjectData.isActive
        subject.sortOrder = 0

        print("Imported subject: \(subjectData.name)")
    }

    private func importVersions(_ versionsData: [SubjectVersionData], for subjectId: String) throws {
        guard let subject = try fetchExistingSubject(id: subjectId) else {
            throw ImportError.invalidFormat("Subject not found for versions")
        }

        for versionData in versionsData {
            let existingVersion = try fetchExistingVersion(id: versionData.id)
            let version = existingVersion ?? SubjectVersion(context: self.context)

            version.id = versionData.id
            version.version = versionData.version
            version.name = versionData.name
            version.isLatest = versionData.isLatest
            version.isSupported = versionData.isSupported
            version.changelog = versionData.changelog
            version.subject = subject

            if let releaseDateString = versionData.releaseDate {
                version.releaseDate = self.dateFormatter.date(from: releaseDateString)
            }

            print("Imported version: \(versionData.name)")
        }
    }

    private func importCategories(_ categoriesData: [CategoryData], for subjectId: String) throws {
        guard let subject = try fetchExistingSubject(id: subjectId) else {
            throw ImportError.invalidFormat("Subject not found for categories")
        }

        for categoryData in categoriesData {
            let existingCategory = try fetchExistingCategory(id: categoryData.id)
            let category = existingCategory ?? Category(context: self.context)

            category.id = categoryData.id
            category.name = categoryData.name
            category.categoryDescription = categoryData.description
            category.sortOrder = Int16(categoryData.sortOrder)
            category.iconName = categoryData.iconName
            category.color = categoryData.color
            category.isCore = categoryData.isCore
            category.subject = subject

            print("Imported category: \(categoryData.name)")
        }
    }

    private func importTopics(_ topicsData: [TopicData], categories: [CategoryData]) throws {
        var categoryMap: [String: Category] = [:]

        for categoryData in categories {
            if let category = try fetchExistingCategory(id: categoryData.id) {
                categoryMap[categoryData.id] = category
            }
        }

        var topicMap: [String: Topic] = [:]

        for topicData in topicsData {
            let existingTopic = try fetchExistingTopic(id: topicData.id)
            let topic = existingTopic ?? Topic(context: self.context)

            topic.id = topicData.id
            topic.name = topicData.name
            topic.topicDescription = topicData.description
            topic.difficulty = Int16(topicData.difficulty)
            topic.estimatedTime = Int16(topicData.estimatedTime)
            topic.isCore = topicData.isCore
            topic.sortOrder = Int16(topicData.sortOrder)

            for categoryId in topicData.categories {
                if let category = categoryMap[categoryId] {
                    topic.addToCategories(category)
                }
            }

            topicMap[topicData.id] = topic
            print("Imported topic: \(topicData.name)")
        }

        for topicData in topicsData {
            guard let topic = topicMap[topicData.id] else { continue }

            for prerequisiteId in topicData.prerequisites {
                if let prerequisite = topicMap[prerequisiteId] {
                    topic.addToPrerequisites(prerequisite)
                }
            }
        }
    }

    private func importLearningResources(_ resourcesData: [LearningResourceData]) throws {
        for resourceData in resourcesData {
            let existingResource = try fetchExistingLearningResource(id: resourceData.id)
            let resource = existingResource ?? LearningResource(context: self.context)

            resource.id = resourceData.id
            resource.title = resourceData.title
            resource.resourceDescription = resourceData.description
            resource.url = resourceData.url
            resource.type = resourceData.type
            resource.difficulty = Int16(resourceData.difficulty)
            resource.estimatedTime = Int16(resourceData.estimatedTime)
            resource.isOfficial = resourceData.isOfficial
            resource.language = resourceData.language
            resource.rating = 0.0
            resource.dateAdded = Date()

            for topicId in resourceData.topics {
                if let topic = try fetchExistingTopic(id: topicId) {
                    resource.topic = topic
                    break // Learning resources are linked to one primary topic
                }
            }

            print("Imported learning resource: \(resourceData.title)")
        }
    }

    private func fetchExistingSubject(id: String) throws -> Subject? {
        let request: NSFetchRequest<Subject> = Subject.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        return try self.context.fetch(request).first
    }

    private func fetchExistingVersion(id: String) throws -> SubjectVersion? {
        let request: NSFetchRequest<SubjectVersion> = SubjectVersion.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        return try self.context.fetch(request).first
    }

    private func fetchExistingCategory(id: String) throws -> Category? {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        return try self.context.fetch(request).first
    }

    private func fetchExistingTopic(id: String) throws -> Topic? {
        let request: NSFetchRequest<Topic> = Topic.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        return try self.context.fetch(request).first
    }

    private func fetchExistingLearningResource(id: String) throws -> LearningResource? {
        let request: NSFetchRequest<LearningResource> = LearningResource.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        return try self.context.fetch(request).first
    }
}
