//
//  AIAssistantSection.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct AIAssistantSection: View {
    @EnvironmentObject private var settingsService: SettingsService
    @EnvironmentObject private var aiService: AIService

    @State private var testResult = ""
    @State private var isTesting = false
    @State private var showOnboarding = false

    var body: some View {
        Section(header: Text("AI Assistant")) {
            // Descriptive text for API key setup
            VStack(alignment: .leading, spacing: 8) {
                Text("AI-Powered Quiz Feedback")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(
                    """
                    SwiftQuiz can provide intelligent feedback on your answers using AI. \
                    Please provide your API key below to enable this feature.
                    """
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)

            Picker("AI Provider", selection: Binding(
                get: { self.settingsService.aiProvider },
                set: { self.settingsService.updateProvider($0) }
            )) {
                ForEach(AIProvider.allCases, id: \.self) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .pickerStyle(.segmented)

            // CloudKit sync status
            HStack {
                Image(systemName: "icloud")
                    .foregroundColor(.blue)
                Text("iCloud Sync")
                Spacer()
                Text("Active")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .font(.caption)

            if self.settingsService.aiProvider == .claude {
                ClaudeAPIKeyView()
            }

            if self.settingsService.aiProvider == .openai {
                OpenAIAPIKeyView()
            }

            if self.settingsService.aiProvider == .disabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No AI Provider Selected")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Choose Claude or OpenAI above to enable AI-powered feedback on your quiz answers.")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Button("Setup AI Assistant") {
                        self.showOnboarding = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button(self.isTesting ? "Testing..." : "Test API Connection") {
                            self.testAPIConnection()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(self.isTesting)

                        if self.isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }

                    if !self.testResult.isEmpty {
                        Text(self.testResult)
                            .font(.caption)
                            .foregroundColor(self.testResult.hasPrefix("✅") ? .green : .red)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .sheet(isPresented: self.$showOnboarding) {
            OnboardingView()
                .environmentObject(self.aiService)
        }
    }

    func testAPIConnection() {
        self.isTesting = true
        self.testResult = ""

        Task {
            let result = switch self.settingsService.aiProvider {
            case .claude:
                await self.settingsService.testClaudeAuthentication()
            case .openai:
                await self.settingsService.testOpenAIAuthentication()
            case .disabled:
                "❌ No AI provider selected"
            }

            await MainActor.run {
                self.testResult = result
                self.isTesting = false
            }
        }
    }
}

#Preview {
    Form {
        AIAssistantSection()
    }
    .environmentObject(SettingsService.shared)
    .environmentObject(AIService.shared)
}
