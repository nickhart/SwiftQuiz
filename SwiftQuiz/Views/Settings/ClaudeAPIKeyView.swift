//
//  ClaudeAPIKeyView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct ClaudeAPIKeyView: View {
    @EnvironmentObject private var settingsService: SettingsService

    var body: some View {
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
}

#Preview {
    Form {
        ClaudeAPIKeyView()
    }
    .environmentObject(SettingsService.shared)
}
