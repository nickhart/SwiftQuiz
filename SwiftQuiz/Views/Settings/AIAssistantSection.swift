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
    @EnvironmentObject private var coordinator: NavigationCoordinator

    @State private var testResult = ""
    @State private var isTesting = false
    @State private var localClaudeKey = ""
    @State private var localOpenAIKey = ""

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
                    apiKey: self.$localClaudeKey
                )
                .onAppear {
                    // Load current value when view appears
                    self.localClaudeKey = self.settingsService.claudeAPIKey
                }
                .onChange(of: self.localClaudeKey) { _, newValue in
                    // Save when user stops typing (debounced)
                    self.saveAPIKeyDebounced(provider: "Claude", key: newValue)
                }
            }

            if self.settingsService.aiProvider == .openai {
                APIKeyInputView(
                    provider: "OpenAI",
                    placeholder: "sk-proj-...",
                    apiKey: self.$localOpenAIKey
                )
                .onAppear {
                    // Load current value when view appears
                    self.localOpenAIKey = self.settingsService.openAIAPIKey
                }
                .onChange(of: self.localOpenAIKey) { _, newValue in
                    // Save when user stops typing (debounced)
                    self.saveAPIKeyDebounced(provider: "OpenAI", key: newValue)
                }
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
                        self.coordinator.showOnboarding()
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

    private func saveAPIKeyDebounced(provider: String, key: String) {
        // Simple approach: save immediately but don't read back
        // This prevents the clearing issue
        do {
            switch provider {
            case "Claude":
                try self.settingsService.createOrUpdateAPIKey(name: "Claude", key: key)
            case "OpenAI":
                try self.settingsService.createOrUpdateAPIKey(name: "OpenAI", key: key)
            default:
                break
            }
            print("✅ Saved \(provider) API key (length: \(key.count))")
        } catch {
            print("❌ Failed to save \(provider) API key: \(error)")
        }
    }
}

#Preview {
    Form {
        AIAssistantSection()
    }
    .environmentObject(SettingsService.shared)
    .environmentObject(AIService.shared)
    .environmentObject(NavigationCoordinator())
}
