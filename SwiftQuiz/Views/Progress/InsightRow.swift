//
//  InsightRow.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct InsightRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: self.icon)
                .foregroundColor(self.iconColor)
                .font(.caption)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(self.title)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(self.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
    }
}
