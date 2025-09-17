//
//  FreeformQuestionView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import CoreData
import SwiftUI

struct FreeformQuestionView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var viewModel: QuizSessionViewModel

    @State private var userInput: String = ""
    @State private var isSubmitted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let question = viewModel.currentQuestion {
                VStack(alignment: .leading, spacing: 4) {
                    Text(question.id ?? "unknown")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(question.question ?? "")
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                }

                TextEditor(text: self.$userInput)
                    .frame(height: 120)
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .onChange(of: self.userInput) { _, newValue in
                        self.viewModel.currentUserInput = newValue
                    }

                HStack(spacing: 12) {
                    if !self.isSubmitted {
                        Button("Submit") {
                            self.viewModel.submitAnswer(self.userInput)
                            self.isSubmitted = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(self.userInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    } else {
                        Button("Next Question") {
                            self.viewModel.selectNextQuestion()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                if self.isSubmitted {
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
        .onAppear {
            // Sync with view model when view appears (e.g., question changes)
            self.userInput = self.viewModel.currentUserInput
        }
        .onChange(of: self.viewModel.currentQuestion?.id) { _, _ in
            // Clear local input when question changes
            self.userInput = ""
            self.isSubmitted = false
        }
    }
}

#Preview {
    @Previewable @State var viewModel: QuizSessionViewModel = {
        let context = PersistenceController.preview.container.viewContext
        let request = Question.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@", "freeform")
        request.fetchLimit = 1

        let result = try? context.fetch(request)
        let question = result?.first
        let vm = QuizSessionViewModel()
        vm.setup(with: context)
        vm.questions = [question].compactMap { $0 }
        vm.currentIndex = 0
        return vm
    }()

    FreeformQuestionView(viewModel: viewModel)
}
