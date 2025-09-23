//
//  HelpSupportSection.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct HelpSupportSection: View {
    @EnvironmentObject private var settingsService: SettingsService
    @EnvironmentObject private var notificationService: NotificationService

    @State private var showOnboarding = false
    @State private var showResetConfirmation = false

    var body: some View {
        Section(header: Text("Help & Support")) {
            Button("Show AI Setup Guide") {
                self.showOnboarding = true
            }

            Button("Reset All Settings") {
                self.showResetConfirmation = true
            }
            .foregroundColor(.red)
        }
        .sheet(isPresented: self.$showOnboarding) {
            OnboardingView()
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

    private func resetAllSettings() {
        // Reset AI settings via SettingsService
        self.settingsService.updateProvider(.disabled)
        self.settingsService.updateClaudeAPIKey("")
        self.settingsService.updateOpenAIAPIKey("")

        // Reset category settings
        self.settingsService.enabledCategories = ["Swift"]
        UserDefaults.standard.removeObject(forKey: "enabled_categories")

        // Reset notification settings
        self.notificationService.toggleReminder(false)

        // Reset onboarding
        UserDefaults.standard.removeObject(forKey: "has_completed_onboarding")

        print("🔄 Settings: All settings have been reset")
    }
}

#Preview {
    Form {
        HelpSupportSection()
    }
    .environmentObject(SettingsService.shared)
    .environmentObject(NotificationService.shared)
}
