//
//  ContentView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import SwiftUI
import CoreData

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
            if questions.indices.contains(currentIndex) {
                QuestionCardView(question: questions[currentIndex])
            } else {
                Text("No questions available.")
            }
            
            HStack {
                Button("Dismiss") {
                    // TODO: implement dismiss logic
                }
                .buttonStyle(.bordered)
                
                Menu("Snooze") {
                    Button("1 hour") { /* TODO */ }
                    Button("2 hours") { /* TODO */ }
                    Button("4 hours") { /* TODO */ }
                    Button("8 hours") { /* TODO */ }
                    Button("1 day") { /* TODO */ }
                }
                .buttonStyle(.bordered)
                
                Button("Next") {
                    if currentIndex + 1 < questions.count {
                        currentIndex += 1
                    } else {
                        currentIndex = 0
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
