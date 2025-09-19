//
//  OpenAIAPIKeyView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct OpenAIAPIKeyView: View {
    @EnvironmentObject private var settingsService: SettingsService

    var body: some View {
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
}

#Preview {
    Form {
        OpenAIAPIKeyView()
    }
    .environmentObject(SettingsService.shared)
}
