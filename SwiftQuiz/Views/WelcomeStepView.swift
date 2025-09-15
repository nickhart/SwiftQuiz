//
//  WelcomeStepView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/15/25.
//

import SwiftUI

// swiftlint:disable file_types_order

// MARK: - Welcome Step View

struct WelcomeStepView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "brain")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Welcome to SwiftQuiz")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Learn Swift with AI-powered feedback")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "questionmark.circle",
                    title: "Smart Questions",
                    description: "Curated Swift programming questions"
                )

                FeatureRow(
                    icon: "brain",
                    title: "AI Feedback",
                    description: "Get intelligent feedback on your answers"
                )

                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Progress",
                    description: "Monitor your learning journey"
                )
            }

            Button("Get Started") {
                self.onNext()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: self.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(self.title)
                    .font(.headline)

                Text(self.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - AI Provider Selection View

struct AIProviderSelectionView: View {
    @Binding var selectedProvider: AIProvider
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)

                Text("Choose Your AI Assistant")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("Select an AI provider for personalized feedback")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                ForEach([AIProvider.claude, AIProvider.openai], id: \.self) { provider in
                    ProviderSelectionCard(
                        provider: provider,
                        isSelected: self.selectedProvider == provider,
                        onSelect: { self.selectedProvider = provider }
                    )
                }
            }

            VStack(spacing: 12) {
                Button("Continue") {
                    self.onNext()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(self.selectedProvider == .disabled)

                Button("Back") {
                    self.onBack()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

// MARK: - Provider Selection Card

struct ProviderSelectionCard: View {
    let provider: AIProvider
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: self.onSelect) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(self.provider.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(self.providerDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if self.isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(self.isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var providerDescription: String {
        switch self.provider {
        case .claude:
            """
            Claude provides detailed, thoughtful feedback on your Swift answers \
            with clear explanations and helpful suggestions.
            """
        case .openai:
            "OpenAI's models offer quick, accurate evaluations of your code with practical improvement tips."
        case .disabled:
            ""
        }
    }
}

// MARK: - API Key Setup View

struct APIKeySetupView: View {
    @Binding var apiKey: String
    @Binding var showError: Bool
    @Binding var errorMessage: String
    let selectedProvider: AIProvider
    let onNext: () -> Void
    let onBack: () -> Void
    let onTestKey: () async -> Void

    @State private var isTesting = false

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "key")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)

                Text("API Key Setup")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("Enter your \(self.selectedProvider.rawValue) API key to enable AI feedback")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("API Key")
                    .font(.headline)

                SecureField("Enter your API key...", text: self.$apiKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))

                APIKeyInstructionsView(provider: self.selectedProvider)
            }

            if self.showError {
                Text(self.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            VStack(spacing: 12) {
                Button(self.isTesting ? "Testing..." : "Test & Continue") {
                    Task {
                        self.isTesting = true
                        await self.onTestKey()
                        self.isTesting = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(self.apiKey.isEmpty || self.isTesting)

                Button("Back") {
                    self.onBack()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

// MARK: - API Key Instructions View

struct APIKeyInstructionsView: View {
    let provider: AIProvider

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to get your API key:")
                .font(.subheadline)
                .fontWeight(.medium)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(self.instructions, id: \.self) { instruction in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.blue)
                        Text(instruction)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    private var instructions: [String] {
        switch self.provider {
        case .claude:
            [
                "Visit console.anthropic.com",
                "Sign up or log in to your account",
                "Go to API Keys section",
                "Create a new API key",
                "Copy and paste it above",
            ]
        case .openai:
            [
                "Visit platform.openai.com",
                "Sign up or log in to your account",
                "Go to API Keys section",
                "Create a new API key",
                "Copy and paste it above",
            ]
        case .disabled:
            []
        }
    }
}

// MARK: - Completion View

struct OnboardingCompletionView: View {
    let selectedProvider: AIProvider
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("Setup Complete!")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("You're ready to start learning Swift with AI-powered feedback")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 16) {
                CompletionFeatureRow(
                    icon: "brain",
                    title: "AI Feedback Enabled",
                    description: "Using \(self.selectedProvider.rawValue) for intelligent responses"
                )

                CompletionFeatureRow(
                    icon: "icloud",
                    title: "Secure & Synced",
                    description: "Your settings are encrypted and sync across devices"
                )

                CompletionFeatureRow(
                    icon: "play.circle",
                    title: "Ready to Learn",
                    description: "Start answering questions and get instant feedback"
                )
            }

            Button("Start Learning") {
                self.onComplete()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

// MARK: - Completion Feature Row

struct CompletionFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: self.icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(self.title)
                    .font(.headline)

                Text(self.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// swiftlint:enable file_types_order
