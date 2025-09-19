//
//  StatItem.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct StatItem: View {
    let title: String
    let value: Double
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(self.title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .bottom, spacing: 2) {
                Text("\(Int(self.value))")
                    .font(.title3)
                    .fontWeight(.semibold)

                if !self.unit.isEmpty {
                    Text(self.unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}
