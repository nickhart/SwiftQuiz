//
//  AnalyticsView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/17/25.
//

import SwiftUI

struct AnalyticsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Progress & Analytics")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Coming Soon")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Track your Swift learning progress, performance trends, and areas for improvement.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    AnalyticsView()
}
