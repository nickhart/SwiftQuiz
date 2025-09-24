import CoreData
import Foundation

struct CategoryImportFile: Codable {
    let category: String
    let categoryDescription: String?
    let questions: [QuestionData]
}

struct QuestionData: Codable {
    let id: String
    let type: String
    let question: String
    let choices: [String]?
    let answer: String?
    let explanation: String?
    let tags: [String]
}

// MARK: - Result Types

struct ImportResult {
    var questionsCreated = 0
    var questionsUpdated = 0
    var categoryCreated = false
    var errors: [String] = []

    var totalProcessed: Int {
        self.questionsCreated + self.questionsUpdated
    }

    mutating func merge(_ other: ImportResult) {
        self.questionsCreated += other.questionsCreated
        self.questionsUpdated += other.questionsUpdated
        self.errors.append(contentsOf: other.errors)
    }
}

enum ImportError: LocalizedError {
    case fileNotFound(String)
    case invalidFormat(String)
    case coreDataError(Error)

    var errorDescription: String? {
        switch self {
        case let .fileNotFound(filename):
            "File not found: \(filename).json"
        case let .invalidFormat(message):
            "Invalid file format: \(message)"
        case let .coreDataError(error):
            "Core Data error: \(error.localizedDescription)"
        }
    }
}

final class CategoryImportService {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// Imports questions from a JSON file with category structure
    func importQuestions(from url: URL, saveAfterImport: Bool = true) throws -> ImportResult {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let importFile = try decoder.decode(CategoryImportFile.self, from: data)

        return try self.importQuestions(from: importFile, saveAfterImport: saveAfterImport)
    }

    /// Imports questions from bundle resource
    func importQuestions(fromJSONFileNamed filename: String, saveAfterImport: Bool = true) throws -> ImportResult {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw ImportError.fileNotFound(filename)
        }
        return try self.importQuestions(from: url, saveAfterImport: saveAfterImport)
    }

    /// Synchronous import for compatibility (used in previews)
    func importQuestionsSync(from url: URL, saveAfterImport: Bool = true) throws -> Int {
        let result = try importQuestions(from: url, saveAfterImport: saveAfterImport)
        return result.totalProcessed
    }

    /// Core import logic
    private func importQuestions(from importFile: CategoryImportFile, saveAfterImport: Bool) throws -> ImportResult {
        var result = ImportResult()

        try context.performAndWait {
            // Create or find category
            let category = try findOrCreateCategory(
                name: importFile.category,
                description: importFile.categoryDescription
            )

            result.categoryCreated = ((category.questions?.count ?? 0) != 0)

            // Process each question
            for questionData in importFile.questions {
                do {
                    let questionResult = try importQuestion(questionData, category: category)
                    result.merge(questionResult)
                } catch {
                    print("❌ Failed to import question \(questionData.id): \(error)")
                    result.errors.append("Question \(questionData.id): \(error.localizedDescription)")
                }
            }

            // Save if requested
            if saveAfterImport, self.context.hasChanges {
                try self.context.save()
                print("✅ Saved \(result.totalProcessed) questions to CoreData")
            }
        }

        return result
    }

    /// Finds or creates a category entity
    private func findOrCreateCategory(name: String, description: String?) throws -> Category {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1

        if let existing = try context.fetch(request).first {
            // Update description if provided and different
            if let newDescription = description, existing.categoryDescription != newDescription {
                existing.categoryDescription = newDescription
            }
            return existing
        }

        // Create new category
        let category = Category(context: context)
        category.id = UUID().uuidString
        category.name = name
        category.categoryDescription = description

        print("✅ Created new category: \(name)")
        return category
    }

    /// Finds or creates tag entities
    private func findOrCreateTags(names: [String]) throws -> Set<Tag> {
        var tags = Set<Tag>()

        for tagName in names {
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.predicate = NSPredicate(format: "name == %@", tagName)
            request.fetchLimit = 1

            let tag: Tag
            if let existing = try context.fetch(request).first {
                tag = existing
            } else {
                tag = Tag(context: self.context)
                tag.id = UUID().uuidString
                tag.name = tagName
                print("✅ Created new tag: \(tagName)")
            }
            tags.insert(tag)
        }

        return tags
    }

    /// Imports a single question
    private func importQuestion(_ questionData: QuestionData, category: Category) throws -> ImportResult {
        var result = ImportResult()

        // Find existing question
        let request: NSFetchRequest<Question> = Question.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", questionData.id)
        request.fetchLimit = 1

        let question: Question
        let isNew: Bool

        if let existing = try context.fetch(request).first {
            question = existing
            isNew = false
        } else {
            question = Question(context: self.context)
            question.id = questionData.id
            isNew = true
        }

        // Update question properties
        question.type = questionData.type
        question.question = questionData.question
        question.choices = questionData.choices
        question.answer = questionData.answer
        question.explanation = questionData.explanation

        // Set category relationship
        question.category = category

        // Set tag relationships
        let tags = try findOrCreateTags(names: questionData.tags)
        question.tags = NSSet(set: tags)

        if isNew {
            result.questionsCreated += 1
            print("✅ Created question: \(questionData.id)")
        } else {
            result.questionsUpdated += 1
            print("🔄 Updated question: \(questionData.id)")
        }

        return result
    }
}
