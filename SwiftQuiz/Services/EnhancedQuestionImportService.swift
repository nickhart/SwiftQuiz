//
//  EnhancedQuestionImportService.swift
//  SwiftQuiz
//
//  Created by Claude on 12/20/24.
//

import CoreData
import Foundation

struct EnhancedQuestionsFile: Codable {
    let formatVersion: String
    let subject: String
    let lastUpdated: String
    let questions: [EnhancedQuestionData]
}

struct EnhancedQuestionData: Codable {
    let id: String
    let question: String
    let answer: String?
    let explanation: String
    let type: String
    let category: String
    let topics: [String]
    let subjectVersion: String?
    let difficulty: Int
    let bloomsLevel: Int
    let estimatedTime: Int
    let choices: [String]?
    let tags: [String]
    let learningResources: [String]
    let metadata: [String: AnyCodable]?
}

struct AnyCodable: Codable {
    let value: Any

    init(_ value: (some Any)?) {
        self.value = value ?? ()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map(\.value)
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            self.value = ()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self.value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            let anyArray = array.map { AnyCodable($0) }
            try container.encode(anyArray)
        case let dictionary as [String: Any]:
            let anyDictionary = dictionary.mapValues { AnyCodable($0) }
            try container.encode(anyDictionary)
        default:
            try container.encodeNil()
        }
    }
}

@MainActor
final class EnhancedQuestionImportService: ObservableObject {
    enum ImportError: LocalizedError {
        case fileNotFound(String)
        case invalidFormat(String)
        case subjectNotFound(String)
        case coreDataError(Error)

        var errorDescription: String? {
            switch self {
            case let .fileNotFound(filename):
                "Questions file '\(filename)' not found"
            case let .invalidFormat(reason):
                "Invalid questions format: \(reason)"
            case let .subjectNotFound(subjectId):
                "Subject '\(subjectId)' not found. Import taxonomy first."
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

    func importQuestions(from filename: String) async throws {
        print("Starting enhanced questions import from \(filename)")

        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw ImportError.fileNotFound("\(filename).json")
        }

        let data = try Data(contentsOf: url)
        let questionsFile = try JSONDecoder().decode(EnhancedQuestionsFile.self, from: data)

        try await withCheckedThrowingContinuation { continuation in
            self.context.perform {
                do {
                    try self.validateSubjectExists(questionsFile.subject)
                    try self.importQuestions(questionsFile.questions, subjectId: questionsFile.subject)
                    try self.context.save()
                    print(
                        """
                        Successfully imported \(questionsFile.questions.count) questions for subject: \(questionsFile
                            .subject
                        )
                        """
                    )
                    continuation.resume()
                } catch {
                    print("Error importing questions: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func validateSubjectExists(_ subjectId: String) throws {
        let request: NSFetchRequest<Subject> = Subject.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", subjectId)

        guard try self.context.fetch(request).first != nil else {
            throw ImportError.subjectNotFound(subjectId)
        }
    }

    private func importQuestions(_ questionsData: [EnhancedQuestionData], subjectId: String) throws {
        let subject = try fetchSubject(id: subjectId)

        for questionData in questionsData {
            try self.importQuestion(questionData, subject: subject)
        }
    }

    private func importQuestion(_ questionData: EnhancedQuestionData, subject: Subject) throws {
        let contentHash = self.calculateContentHash(for: questionData)

        let existingQuestion = try fetchExistingQuestion(id: questionData.id)

        if let existing = existingQuestion,
           existing.contentHash == contentHash {
            print("Question \(questionData.id) unchanged, skipping")
            return
        }

        let question = existingQuestion ?? Question(context: self.context)

        question.id = questionData.id
        question.question = questionData.question
        question.answer = questionData.answer
        question.explanation = questionData.explanation
        question.type = questionData.type
        question.difficulty = Int16(questionData.difficulty)
        question.bloomsLevel = Int16(questionData.bloomsLevel)
        question.estimatedTime = Int16(questionData.estimatedTime)
        question.contentHash = contentHash
        question.subject = subject

        if let choices = questionData.choices {
            question.choices = choices as NSObject
        }

        question.tags = questionData.tags as NSObject

        if let category = try fetchCategory(id: questionData.category) {
            question.primaryCategory = category
            question.category = category.name
        }

        question.topics = NSSet()
        for topicId in questionData.topics {
            if let topic = try fetchTopic(id: topicId) {
                question.addToTopics(topic)
            }
        }

        if let version = questionData.subjectVersion {
            question.subjectVersion = try self.fetchSubjectVersion(version: version, subjectId: subject.id!)
        }

        if let metadataDict = questionData.metadata {
            let jsonData = try JSONSerialization.data(withJSONObject: metadataDict.mapValues { $0.value })
            question.metadata = jsonData as NSObject
        }

        print("Imported question: \(questionData.id)")
    }

    private func calculateContentHash(for questionData: EnhancedQuestionData) -> String {
        let hashSource = """
        \(questionData.question)\(questionData.answer ?? "")\(questionData.explanation)\(questionData
            .type
        )\(questionData.difficulty)\(questionData.bloomsLevel)
        """
        return hashSource.sha256
    }

    private func fetchSubject(id: String) throws -> Subject {
        let request: NSFetchRequest<Subject> = Subject.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)

        guard let subject = try context.fetch(request).first else {
            throw ImportError.subjectNotFound(id)
        }

        return subject
    }

    private func fetchExistingQuestion(id: String) throws -> Question? {
        let request: NSFetchRequest<Question> = Question.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        return try self.context.fetch(request).first
    }

    private func fetchCategory(id: String) throws -> Category? {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        return try self.context.fetch(request).first
    }

    private func fetchTopic(id: String) throws -> Topic? {
        let request: NSFetchRequest<Topic> = Topic.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        return try self.context.fetch(request).first
    }

    private func fetchSubjectVersion(version: String, subjectId: String) throws -> SubjectVersion? {
        let request: NSFetchRequest<SubjectVersion> = SubjectVersion.fetchRequest()
        request.predicate = NSPredicate(format: "version == %@ AND subject.id == %@", version, subjectId)
        return try self.context.fetch(request).first
    }
}

extension String {
    var sha256: String {
        let data = Data(self.utf8)
        let hashed = data.withUnsafeBytes { buffer in
            var digest = [UInt8](repeating: 0, count: 32)
            _ = digest.withUnsafeMutableBufferPointer { digestBuffer in
                CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), digestBuffer.baseAddress)
            }
            return digest
        }
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

import CommonCrypto
