//
//  QuestionImportService.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//


import Foundation
import CoreData

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

final class QuestionImportService {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    @discardableResult
    internal func importQuestionsSync(from url: URL, saveAfterImport: Bool) throws -> Int {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let codableQuestions = try decoder.decode([CodableQuestion].self, from: data)
        
        var importedCount = 0
        
        self.context.performAndWait {
            for codable in codableQuestions {
                let fetchRequest: NSFetchRequest<Question> = Question.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", codable.id)
                fetchRequest.fetchLimit = 1
                
                let existing = (try? self.context.fetch(fetchRequest))?.first
                let question = existing ?? Question(context: self.context)
                
                question.id = codable.id
                question.type = codable.type
                question.question = codable.question
                question.choices = codable.choices as NSObject?
                question.answer = codable.answer
                question.explanation = codable.explanation
                question.difficulty = codable.difficulty
                question.tags = codable.tags as NSObject?
                question.sourceTitle = codable.source?.title
                question.sourceURL = codable.source?.url
                
                if existing == nil {
                    importedCount += 1
                }
            }
            
            if saveAfterImport, self.context.hasChanges {
                try? self.context.save()
            }
        }
        
        return importedCount
    }
    
    func importQuestions(fromJSONFileNamed filename: String, saveAfterImport: Bool = true, completion: @escaping (Result<Int, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "QuestionImportService", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found"])))
                }
                return
            }
            
            do {
                let importedCount = try self.importQuestionsSync(from: url, saveAfterImport: saveAfterImport)
                DispatchQueue.main.async {
                    completion(.success(importedCount))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
