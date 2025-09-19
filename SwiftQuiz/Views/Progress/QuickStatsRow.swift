//
//  QuickStatsRow.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct QuickStatsRow: View {
    let timeframe: TimeframeFilter

    var body: some View {
        HStack(spacing: 12) {
            QuickStatCard(
                title: "Quizzes",
                value: "12",
                change: "+3",
                isPositive: true,
                icon: "doc.text.fill"
            )

            QuickStatCard(
                title: "Avg Score",
                value: "87%",
                change: "+5%",
                isPositive: true,
                icon: "chart.line.uptrend.xyaxis"
            )

            QuickStatCard(
                title: "Study Time",
                value: "2h 15m",
                change: "+30m",
                isPositive: true,
                icon: "clock.fill"
            )
        }
    }
}
