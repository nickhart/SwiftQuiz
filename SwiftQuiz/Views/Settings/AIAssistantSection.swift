//
//  AIAssistantSection.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct APIKeyInputView: View {
    let provider: String
    let placeholder: String
    @Binding var apiKey: String

    @State private var isSecureEntry = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(self.provider) API Key")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Button(action: { self.isSecureEntry.toggle() }, label: {
                    Image(systemName: self.isSecureEntry ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                })
                .buttonStyle(.plain)
            }

            HStack {
                Group {
                    if self.isSecureEntry {
                        SecureField(self.placeholder, text: self.$apiKey)
                    } else {
                        TextField(self.placeholder, text: self.$apiKey)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .font(.caption)

                if !self.apiKey.isEmpty {
                    Button("Clear") {
                        self.apiKey = ""
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }

            if self.apiKey.isEmpty {
                Text("Enter your \(self.provider) API key to enable AI-powered feedback")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("API key saved securely in Keychain")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

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
                APIKeyInputView(
                    provider: "Claude",
                    placeholder: "sk-ant-api...",
                    apiKey: Binding(
                        get: { self.settingsService.claudeAPIKey },
                        set: { self.settingsService.claudeAPIKey = $0 }
                    )
                )
            }

            if self.settingsService.aiProvider == .openai {
                APIKeyInputView(
                    provider: "OpenAI",
                    placeholder: "sk-proj-...",
                    apiKey: Binding(
                        get: { self.settingsService.openAIAPIKey },
                        set: { self.settingsService.openAIAPIKey = $0 }
                    )
                )
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
            let result = await self.settingsService.testCurrentAPIAuthentication()

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
