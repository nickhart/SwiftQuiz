//
//  FreeformQuestionView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import SwiftUI

struct FreeformQuestionView: View {
    let question: Question?
    @State private var userInput: String = ""
    @State private var isSubmitted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let question = question {
                Text(question.question ?? "")
                    .font(.headline)

                TextEditor(text: $userInput)
                    .frame(height: 120)
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                Button("Submit") {
                    isSubmitted = true
                }
                .buttonStyle(.borderedProminent)

                if isSubmitted {
                    if let answer = question.answer {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("💡 Example Answer:")
                                .font(.subheadline)
                                .bold()
                            Text(answer)
                                .padding(8)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }

                    if let explanation = question.explanation {
                        Text(explanation)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                }
            } else {
                Text("No question available.")
            }
        }
        .padding()
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let request = Question.fetchRequest()
    request.predicate = NSPredicate(format: "type == %@", "freeform")
    request.fetchLimit = 1

    let result = try? context.fetch(request)
    let question = result?.first

    return FreeformQuestionView(question: question)
}
