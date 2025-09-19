//
//  PerformanceTrendsView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct PerformanceTrendsView: View {
    @State private var selectedMetric: PerformanceMetric = .score
    @State private var selectedTimeframe: TimeframeFilter = .month
    @State private var performanceData: [PerformanceDataPoint] = []

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header with controls
                VStack(alignment: .leading, spacing: 16) {
                    Text("Performance Trends")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    HStack {
                        // Metric selector
                        Menu(self.selectedMetric.displayName) {
                            ForEach(PerformanceMetric.allCases, id: \.self) { metric in
                                Button(metric.displayName) {
                                    self.selectedMetric = metric
                                }
                            }
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        // Timeframe selector
                        Menu(self.selectedTimeframe.displayName) {
                            ForEach(TimeframeFilter.allCases, id: \.self) { timeframe in
                                Button(timeframe.displayName) {
                                    self.selectedTimeframe = timeframe
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)

                // Main chart
                PerformanceChart(
                    data: self.performanceData,
                    metric: self.selectedMetric,
                    timeframe: self.selectedTimeframe
                )
                .padding(.horizontal)

                // Trend insights
                TrendInsightsCard(data: self.performanceData, metric: self.selectedMetric)
                    .padding(.horizontal)

                // Detailed statistics
                DetailedStatsGrid(data: self.performanceData, metric: self.selectedMetric)
                    .padding(.horizontal)

                // Time-based performance breakdown
                TimeBasedPerformanceCard()
                    .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Performance Trends")
        #if os(iOS)
            .sqNavigationBarStyle(.inline)
        #endif
            .onAppear {
                self.loadPerformanceData()
            }
            .onChange(of: self.selectedTimeframe) {
                self.loadPerformanceData()
            }
    }

    private func loadPerformanceData() {
        self.performanceData = self.generateSampleData(for: self.selectedTimeframe)
    }

    private func generateSampleData(for timeframe: TimeframeFilter) -> [PerformanceDataPoint] {
        let days = min(timeframe.daysBack, 90)
        let calendar = Calendar.current

        return (0..<days).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()

            return PerformanceDataPoint(
                date: date,
                score: Double.random(in: 0.6...1.0),
                accuracy: Double.random(in: 0.7...1.0),
                speed: Double.random(in: 0.5...1.0),
                quizzesTaken: Int.random(in: 0...5),
                studyTime: Double.random(in: 0...120)
            )
        }.reversed()
    }
}

#Preview {
    PerformanceTrendsView()
}
