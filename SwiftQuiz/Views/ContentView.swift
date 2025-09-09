//
//  ContentView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: Question.entity(),
        sortDescriptors: [],
        predicate: nil,
        animation: .default
    )
    private var questions: FetchedResults<Question>

    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: 20) {
            if self.questions.indices.contains(self.currentIndex) {
                QuestionCardView(question: self.questions[self.currentIndex])
            } else {
                Text("No questions available.")
            }

            HStack {
                Button("Dismiss") {
                    // implement dismiss logic
                }
                .buttonStyle(.bordered)

                Menu("Snooze") {
                    Button("1 hour") { /* snooze 1 hour */ }
                    Button("2 hours") { /* snooze 2 hours */ }
                    Button("4 hours") { /* snooze 4 hours */ }
                    Button("8 hours") { /* snooze 8 hours */ }
                    Button("1 day") { /* snooze 24 hours */ }
                }
                .buttonStyle(.bordered)

                Button("Next") {
                    if self.currentIndex + 1 < self.questions.count {
                        self.currentIndex += 1
                    } else {
                        self.currentIndex = 0
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
