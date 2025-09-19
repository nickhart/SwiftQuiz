//
//  TodaysQuizView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/17/25.
//

import SwiftUI

struct TodaysQuizView: View {
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @EnvironmentObject private var viewModel: MainViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Today's Quiz")
                .font(.largeTitle)
                .fontWeight(.bold)

            switch self.viewModel.loadingState {
            case .idle, .loading:
                ProgressView("Loading questions...")
            case .loaded:
                VStack(spacing: 16) {
                    Text("Ready for your daily quiz!")
                        .font(.title2)
                        .multilineTextAlignment(.center)

                    Button("Start Today's Quiz") {
                        self.coordinator.startQuizSession()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.headline)
                }
            case let .error(message):
                VStack(spacing: 8) {
                    Text("Error loading questions")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    TodaysQuizView()
        .environmentObject(NavigationCoordinator())
        .environmentObject(MainViewModel())
}
