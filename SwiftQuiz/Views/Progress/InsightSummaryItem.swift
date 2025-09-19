//
//  InsightSummaryItem.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct InsightSummaryItem: View {
    let count: Int
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: self.icon)
                .foregroundColor(self.color)
                .font(.title2)

            Text("\(self.count)")
                .font(.title3)
                .fontWeight(.bold)

            Text(self.title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
