//
//  QuestionCardView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import CoreData
import SwiftUI

struct QuestionCardView: View {
    @ObservedObject var viewModel: QuizSessionViewModel

    var body: some View {
        Group {
            switch self.viewModel.currentQuestion?.questionTypeEnum {
            case .multipleChoice:
                MultipleChoiceQuestionView(viewModel: self.viewModel)
            case .shortAnswer:
                ShortAnswerQuestionView(viewModel: self.viewModel)
            case .freeform:
                FreeformQuestionView(viewModel: self.viewModel)
            case .none:
                Text("No question available.")
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)).shadow(radius: 4))
    }
}

#Preview {
    @Previewable @State var viewModel: QuizSessionViewModel = {
        let context = PersistenceController.preview.container.viewContext
        let fetchRequest: NSFetchRequest<Question> = Question.fetchRequest()
        fetchRequest.fetchLimit = 1
        let previewQuestions = (try? context.fetch(fetchRequest)) ?? []

        let vm = QuizSessionViewModel()
        vm.setup(with: context)
        vm.questions = previewQuestions
        vm.currentIndex = 0
        return vm
    }()

    QuestionCardView(viewModel: viewModel)
}
