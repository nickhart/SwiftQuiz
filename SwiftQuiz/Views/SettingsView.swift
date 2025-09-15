//
//  SettingsView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/14/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var notificationService: NotificationService
    @EnvironmentObject private var settingsService: SettingsService
    @EnvironmentObject private var aiService: AIService
    @Environment(\.dismiss) private var dismiss

    @State private var showOnboarding = false
    @State private var showResetConfirmation = false
    @State private var testResult = ""
    @State private var isTesting = false

    var body: some View {
        NavigationStack {
            Form {
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
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Claude API Key")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: "lock.shield")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }

                            if self.settingsService.claudeAPIKey.isEmpty {
                                Text(
                                    """
                                    Please provide your Claude API key to use AI feedback. \
                                    Get your API key from console.anthropic.com
                                    """
                                )
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.bottom, 4)
                            }

                            SecureField("sk-ant-api03-...", text: Binding(
                                get: { self.settingsService.claudeAPIKey },
                                set: { self.settingsService.updateClaudeAPIKey($0) }
                            ))
                            .textFieldStyle(.roundedBorder)

                            Text("Stored securely in Keychain and synced via iCloud")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    if self.settingsService.aiProvider == .openai {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("OpenAI API Key")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: "lock.shield")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }

                            if self.settingsService.openAIAPIKey.isEmpty {
                                Text(
                                    """
                                    Please provide your OpenAI API key to use AI feedback. \
                                    Get your API key from platform.openai.com
                                    """
                                )
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.bottom, 4)
                            }

                            SecureField("sk-...", text: Binding(
                                get: { self.settingsService.openAIAPIKey },
                                set: { self.settingsService.updateOpenAIAPIKey($0) }
                            ))
                            .textFieldStyle(.roundedBorder)

                            Text("Stored securely in Keychain and synced via iCloud")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
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

                Section(header: Text("Daily Reminder")) {
                    if self.notificationService.isAuthorized {
                        Toggle("Enable Daily Reminder", isOn: Binding(
                            get: { self.notificationService.isReminderEnabled },
                            set: { self.notificationService.toggleReminder($0) }
                        ))

                        if self.notificationService.isReminderEnabled {
                            DatePicker(
                                "Reminder Time",
                                selection: Binding(
                                    get: { self.notificationService.reminderTime },
                                    set: { self.notificationService.setReminderTime($0) }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .padding(.vertical, 4)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notifications Not Authorized")
                                .foregroundColor(.secondary)

                            Button("Request Permission") {
                                Task {
                                    await self.notificationService.requestPermission()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 8)
                    }
                }

                Section(header: Text("Help & Support")) {
                    Button("Show AI Setup Guide") {
                        self.showOnboarding = true
                    }

                    Button("Reset All Settings") {
                        self.showResetConfirmation = true
                    }
                    .foregroundColor(.red)
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Questions")
                        Spacer()
                        Text("200 Swift Questions")
                            .foregroundColor(.secondary)
                    }

                    if self.settingsService.aiProvider != .disabled {
                        HStack {
                            Text("AI Provider")
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text(self.settingsService.aiProvider.rawValue)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button("Done") {
                            self.dismiss()
                        }
                    }
                }
                .sheet(isPresented: self.$showOnboarding) {
                    OnboardingView()
                        .environmentObject(self.aiService)
                }
                .alert("Reset All Settings", isPresented: self.$showResetConfirmation) {
                    Button("Reset", role: .destructive) {
                        self.resetAllSettings()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text(
                        """
                        This will reset all your preferences including AI settings, notifications, \
                        and onboarding status. This action cannot be undone.
                        """
                    )
                }
        }
    }

    private func resetAllSettings() {
        // Reset AI settings via SettingsService
        self.settingsService.updateProvider(.disabled)
        self.settingsService.updateClaudeAPIKey("")
        self.settingsService.updateOpenAIAPIKey("")

        // Reset notification settings
        self.notificationService.toggleReminder(false)

        // Reset onboarding
        UserDefaults.standard.removeObject(forKey: "has_completed_onboarding")

        print("🔄 Settings: All settings have been reset")
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
    SettingsView()
        .environmentObject(NotificationService.shared)
        .environmentObject(SettingsService.shared)
        .environmentObject(AIService.shared)
}
