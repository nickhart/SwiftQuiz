//
//  PatternInsight.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct PatternInsight: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let metric: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: self.icon)
                .foregroundColor(self.iconColor)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(self.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(self.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(self.metric)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(self.iconColor)
        }
    }
}
