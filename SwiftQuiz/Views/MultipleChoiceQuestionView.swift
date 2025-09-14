//
//  MultipleChoiceQuestionView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import SwiftUI

struct MultipleChoiceQuestionView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var viewModel: QuizSessionViewModel

    @State private var selectedAnswer: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let question = viewModel.currentQuestion {
                VStack(alignment: .leading, spacing: 4) {
                    Text(question.id ?? "unknown")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(question.question ?? "")
                        .font(.headline)
                }

                ForEach(question.choiceList, id: \.self) { choice in
                    Button(action: {
                        self.selectedAnswer = choice
                    }, label: {
                        Text(choice)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.leading)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(self.selectedAnswer == choice ? Color.blue.opacity(0.2) : Color.gray
                                .opacity(0.1)
                            )
                            .cornerRadius(8)
                    })
                }

                if let selected = selectedAnswer, let correct = question.answer {
                    Text(selected == correct ? "✅ Correct!" : "❌ Incorrect. Correct answer: \(correct)")
                        .foregroundColor(selected == correct ? .green : .red)
                        .padding(.top)
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
        .id(self.viewModel.currentQuestion?.id) // Fix animation delay for multiple choice selections
        .onChange(of: self.viewModel.currentQuestion?.id) { _, _ in
            // Clear selection when question changes
            self.selectedAnswer = nil
        }
    }
}

#Preview {
    @Previewable @State var viewModel: QuizSessionViewModel = {
        let context = PersistenceController.preview.container.viewContext
        let request = Question.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@", "multipleChoice")
        request.fetchLimit = 1

        let result = try? context.fetch(request)
        let question = result?.first
        let vm = QuizSessionViewModel()
        vm.setup(with: context)
        vm.questions = [question].compactMap { $0 }
        vm.currentIndex = 0
        return vm
    }()

    MultipleChoiceQuestionView(viewModel: viewModel)
}
