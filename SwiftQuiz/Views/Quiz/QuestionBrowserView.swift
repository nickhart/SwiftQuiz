//
//  QuestionBrowserView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/17/25.
//

import CoreData
import SwiftUI

struct QuestionBrowserView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var settingsService: SettingsService

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Question.category, ascending: true)],
        animation: .default
    )
    private var questions: FetchedResults<Question>

    @State private var selectedCategory: String = "All"
    @State private var searchText: String = ""
    @State private var showingOnlyAnswered: Bool = false
    @State private var showingOnlyUnanswered: Bool = false

    private var availableCategories: [String] {
        let allCategories = Set(self.questions.compactMap(\.category))
        return ["All"] + Array(allCategories).sorted()
    }

    private var filteredQuestions: [Question] {
        var filtered = Array(questions)

        // Filter by category
        if self.selectedCategory != "All" {
            filtered = filtered.filter { $0.category == self.selectedCategory }
        }

        // Filter by search text
        if !self.searchText.isEmpty {
            filtered = filtered.filter { question in
                let questionText = question.question ?? ""
                let tags = question.tags ?? []
                let allText = ([questionText] + tags).joined(separator: " ")
                return allText.localizedCaseInsensitiveContains(self.searchText)
            }
        }

        // Filter by answered status
        if self.showingOnlyAnswered {
            filtered = filtered.filter { $0.userAnswer != nil }
        } else if self.showingOnlyUnanswered {
            filtered = filtered.filter { $0.userAnswer == nil }
        }

        return filtered
    }

    private var questionCountByCategory: [String: Int] {
        var counts: [String: Int] = [:]
        for question in self.questions {
            let category = question.category ?? "Unknown"
            counts[category, default: 0] += 1
        }
        return counts
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Section
            VStack(spacing: 12) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search questions...", text: self.$searchText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.systemGray6)
                .cornerRadius(8)

                // Category Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(self.availableCategories, id: \.self) { (category: String) in
                            let count = category == "All" ? self.questions
                                .count : (self.questionCountByCategory[category] ?? 0)

                            Button(action: {
                                self.selectedCategory = category
                            }, label: {
                                HStack(spacing: 4) {
                                    Text(category)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Text("(\(count))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(self.selectedCategory == category ? Color.blue : Color.systemGray5)
                                .foregroundColor(self.selectedCategory == category ? .white : .primary)
                                .cornerRadius(16)
                            })
                        }
                    }
                    .padding(.horizontal)
                }

                // Filter Toggle Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        self.showingOnlyAnswered.toggle()
                        if self.showingOnlyAnswered {
                            self.showingOnlyUnanswered = false
                        }
                    }, label: {
                        HStack(spacing: 4) {
                            Image(systemName: self.showingOnlyAnswered ? "checkmark.circle.fill" : "circle")
                            Text("Answered")
                                .font(.caption)
                        }
                        .foregroundColor(self.showingOnlyAnswered ? .green : .secondary)
                    })

                    Button(action: {
                        self.showingOnlyUnanswered.toggle()
                        if self.showingOnlyUnanswered {
                            self.showingOnlyAnswered = false
                        }
                    }, label: {
                        HStack(spacing: 4) {
                            Image(systemName: self.showingOnlyUnanswered ? "checkmark.circle.fill" : "circle")
                            Text("Unanswered")
                                .font(.caption)
                        }
                        .foregroundColor(self.showingOnlyUnanswered ? .orange : .secondary)
                    })

                    Spacer()

                    Text("\(self.filteredQuestions.count) questions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.systemBackground)

            Divider()

            // Questions List
            if self.filteredQuestions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No questions found")
                        .font(.title2)
                        .fontWeight(.medium)

                    Text("Try adjusting your search or filter criteria")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                Spacer()
            } else {
                List(self.filteredQuestions, id: \.id) { question in
                    QuestionRowView(question: question)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .listStyle(PlainListStyle())
            }
        }
        .sqNavigationTitle("Question Bank", displayMode: SQNavigationBarDisplayMode.large)
    }
}

#Preview {
    QuestionBrowserView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(SettingsService.shared)
}
