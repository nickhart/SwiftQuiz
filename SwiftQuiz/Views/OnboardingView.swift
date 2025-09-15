//
//  OnboardingView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/15/25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var aiService: AIService
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedProvider: AIProvider = .claude
    @State private var apiKey: String = ""
    @State private var showError = false
    @State private var errorMessage = ""

    enum OnboardingStep: CaseIterable {
        case welcome
        case chooseProvider
        case apiKeySetup
        case complete

        var title: String {
            switch self {
            case .welcome: "Welcome"
            case .chooseProvider: "Choose AI Provider"
            case .apiKeySetup: "API Key Setup"
            case .complete: "Complete"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Progress indicator
                HStack {
                    ForEach(OnboardingStep.allCases, id: \.self) { step in
                        Circle()
                            .fill(step == self.currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.top)

                Spacer()

                // Content based on current step
                Group {
                    switch self.currentStep {
                    case .welcome:
                        WelcomeStepView {
                            withAnimation { self.currentStep = .chooseProvider }
                        }
                    case .chooseProvider:
                        AIProviderSelectionView(
                            selectedProvider: self.$selectedProvider,
                            onNext: { withAnimation { self.currentStep = .apiKeySetup } },
                            onBack: { withAnimation { self.currentStep = .welcome } }
                        )
                    case .apiKeySetup:
                        APIKeySetupView(
                            apiKey: self.$apiKey,
                            showError: self.$showError,
                            errorMessage: self.$errorMessage,
                            selectedProvider: self.selectedProvider,
                            onNext: { withAnimation { self.currentStep = .complete } },
                            onBack: { withAnimation { self.currentStep = .chooseProvider } },
                            onTestKey: self.testAndContinue
                        )
                    case .complete:
                        OnboardingCompletionView(
                            selectedProvider: self.selectedProvider,
                            onComplete: self.completeOnboarding
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut, value: self.currentStep)

                Spacer()
            }
            .navigationTitle(self.currentStep.title)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button("Skip") {
                            self.completeOnboarding()
                        }
                        .foregroundColor(.secondary)
                    }
                }
        }
    }

    func testAndContinue() async {
        // Update the API key in the service
        switch self.selectedProvider {
        case .claude:
            self.aiService.updateClaudeAPIKey(self.apiKey)
        case .openai:
            self.aiService.updateOpenAIAPIKey(self.apiKey)
        case .disabled:
            break
        }

        // Update the provider
        self.aiService.updateProvider(self.selectedProvider)

        // Test the key (simplified for onboarding)
        do {
            _ = try await self.aiService.evaluateAnswer(
                question: "Test question",
                userAnswer: "Test answer",
                correctAnswer: "Test"
            )

            // Success - move to completion
            await MainActor.run {
                withAnimation {
                    self.currentStep = .complete
                }
                self.showError = false
            }
        } catch {
            // Show error
            await MainActor.run {
                self.errorMessage = "Failed to validate API key. Please check your key and try again."
                self.showError = true
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
        self.dismiss()
    }
}
