//
//  QuestionImportService.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import CoreData
import CryptoKit
import Foundation

struct CodableQuestion: Codable {
    let id: String
    let type: String
    let question: String
    let choices: [String]?
    let answer: String?
    let explanation: String?
    let difficulty: Int16
    let tags: [String]
    let source: QuestionSource?

    struct QuestionSource: Codable {
        let title: String?
        let url: String?
    }
}

struct CodableQuestionFile: Codable {
    let category: String
    let questions: [CodableQuestion]
}

final class QuestionImportService {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// Validates question data and logs errors
    private func validateQuestion(_ codable: CodableQuestion) -> [String] {
        var errors: [String] = []

        // Check multiple choice questions have choices
        if codable.type == "multipleChoice" {
            if codable.choices == nil || codable.choices?.isEmpty == true {
                errors.append("Multiple choice question has no choices")
            }
        }

        // Check for missing essential fields
        if codable.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Question text is empty or missing")
        }

        if codable.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Question ID is empty or missing")
        }

        // Check for very short questions that might be malformed
        if codable.question.count < 10 {
            errors.append("Question text suspiciously short (\(codable.question.count) chars)")
        }

        // Check difficulty range
        if codable.difficulty < 1 || codable.difficulty > 5 {
            errors.append("Difficulty (\(codable.difficulty)) outside expected range 1-5")
        }

        // Check for empty tags array
        if codable.tags.isEmpty {
            errors.append("No tags provided")
        }

        return errors
    }

    /// Calculates a hash of the question's content to detect changes
    private func calculateContentHash(for codable: CodableQuestion) -> String {
        let contentData: String = [
            codable.type,
            codable.question,
            codable.choices?.joined(separator: "|") ?? "",
            codable.answer ?? "",
            codable.explanation ?? "",
            String(codable.difficulty),
            codable.tags.joined(separator: "|"),
            codable.source?.title ?? "",
            codable.source?.url ?? "",
        ].joined(separator: "||")

        let hash = SHA256.hash(data: contentData.data(using: .utf8) ?? Data())
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Gets file metadata for change detection
    private func getFileMetadata(for url: URL) -> [String: Any]? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            return [
                "modificationDate": resourceValues.contentModificationDate?.timeIntervalSince1970 ?? 0,
                "fileSize": resourceValues.fileSize ?? 0,
            ]
        } catch {
            print("Failed to get file metadata: \(error)")
            return nil
        }
    }

    /// Checks if file has changed since last import
    private func hasFileChanged(for filename: String, currentMetadata: [String: Any]) -> Bool {
        let key = "lastImport_\(filename)"
        let storedMetadata = UserDefaults.standard.dictionary(forKey: key)

        guard let stored = storedMetadata else {
            // No previous import record
            return true
        }

        let currentModDate = currentMetadata["modificationDate"] as? Double ?? 0
        let storedModDate = stored["modificationDate"] as? Double ?? 0
        let currentSize = currentMetadata["fileSize"] as? Int ?? 0
        let storedSize = stored["fileSize"] as? Int ?? 0

        return currentModDate != storedModDate || currentSize != storedSize
    }

    /// Stores file metadata after successful import
    private func storeFileMetadata(for filename: String, metadata: [String: Any]) {
        let key = "lastImport_\(filename)"
        UserDefaults.standard.set(metadata, forKey: key)
    }

    @discardableResult
    func importQuestionsSync(from url: URL, saveAfterImport: Bool) throws -> Int {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()

        // Try new format first (with category), fallback to old format
        let (codableQuestions, category): ([CodableQuestion], String)
        if let questionFile = try? decoder.decode(CodableQuestionFile.self, from: data) {
            codableQuestions = questionFile.questions
            category = questionFile.category
        } else {
            // Fallback to old format (array of questions without category)
            codableQuestions = try decoder.decode([CodableQuestion].self, from: data)
            category = "Swift" // Default category for legacy files
        }

        var importedCount = 0
        var updatedCount = 0
        var validationErrors: [String: [String]] = [:]

        self.context.performAndWait {
            for codable in codableQuestions {
                // Validate question data
                let errors = self.validateQuestion(codable)
                if !errors.isEmpty {
                    validationErrors[codable.id] = errors
                    print("❌ VALIDATION ERROR for \(codable.id): \(errors.joined(separator: ", "))")
                }
                let fetchRequest: NSFetchRequest<Question> = Question.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", codable.id)
                fetchRequest.fetchLimit = 1

                let existing = (try? self.context.fetch(fetchRequest))?.first
                let newContentHash = self.calculateContentHash(for: codable)

                // Skip if content hasn't changed
                if let existingQuestion = existing,
                   existingQuestion.contentHash == newContentHash {
                    continue
                }

                assert(self.context.persistentStoreCoordinator != nil)
                let question = existing ?? Question(context: self.context)

                // Update question content
                question.id = codable.id
                question.type = codable.type
                question.question = codable.question
                question.category = category
                question.choices = codable.choices as NSObject?
                question.answer = codable.answer
                question.explanation = codable.explanation
                question.difficulty = codable.difficulty
                question.tags = codable.tags as NSObject?
                question.sourceTitle = codable.source?.title
                question.sourceURL = codable.source?.url
                question.contentHash = newContentHash

                if existing == nil {
                    importedCount += 1
                } else {
                    updatedCount += 1
                }
            }

            if saveAfterImport, self.context.hasChanges {
                try? self.context.save()
            }
        }

        // Log validation summary
        if !validationErrors.isEmpty {
            print("\n🚨 VALIDATION SUMMARY: \(validationErrors.count) questions have errors:")
            for (questionId, errors) in validationErrors.sorted(by: { $0.key < $1.key }) {
                print("  • \(questionId): \(errors.joined(separator: "; "))")
            }
            print("")
        }

        print(
            "Questions import completed: \(importedCount) new, \(updatedCount) updated, "
                + "\(validationErrors.count) with errors"
        )
        return importedCount + updatedCount
    }

    func importQuestions(fromJSONFileNamed filename: String, saveAfterImport: Bool = true,
                         completion: @escaping (Result<Int, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(
                        domain: "QuestionImportService",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "File not found"]
                    )))
                }
                return
            }

            // Check if file has changed
            guard let currentMetadata = self.getFileMetadata(for: url) else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(
                        domain: "QuestionImportService",
                        code: 500,
                        userInfo: [NSLocalizedDescriptionKey: "Could not read file metadata"]
                    )))
                }
                return
            }

            if !self.hasFileChanged(for: filename, currentMetadata: currentMetadata) {
                print("Questions file '\(filename)' unchanged - skipping import")
                DispatchQueue.main.async {
                    completion(.success(0))
                }
                return
            }

            do {
                let changedCount = try self.importQuestionsSync(from: url, saveAfterImport: saveAfterImport)

                // Store metadata after successful import
                self.storeFileMetadata(for: filename, metadata: currentMetadata)

                DispatchQueue.main.async {
                    completion(.success(changedCount))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    /// Imports all question files from the Questions directory
    func importAllQuestionFiles(saveAfterImport: Bool = true, completion: @escaping (Result<Int, Error>) -> Void) {
        let questionFiles = ["swift", "swift_advanced", "coredata", "coreanimation"]
        var totalImported = 0
        var remainingFiles = questionFiles.count
        var firstError: Error?

        for filename in questionFiles {
            self.importQuestions(fromJSONFileNamed: filename, saveAfterImport: false) { result in
                switch result {
                case let .success(count):
                    totalImported += count
                case let .failure(error):
                    print("❌ Failed to import \(filename): \(error)")
                    if firstError == nil {
                        firstError = error
                    }
                }

                remainingFiles -= 1
                if remainingFiles == 0 {
                    // All files processed
                    if saveAfterImport, self.context.hasChanges {
                        do {
                            try self.context.save()
                        } catch {
                            completion(.failure(error))
                            return
                        }
                    }

                    if let error = firstError, totalImported == 0 {
                        completion(.failure(error))
                    } else {
                        completion(.success(totalImported))
                    }
                }
            }
        }
    }
}
