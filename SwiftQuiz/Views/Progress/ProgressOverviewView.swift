//
//  ProgressOverviewView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

enum TimeframeFilter: String, CaseIterable {
    case week
    case month
    case threeMonths = "three_months"
    case year
    case allTime = "all_time"

    var displayName: String {
        switch self {
        case .week: "This Week"
        case .month: "This Month"
        case .threeMonths: "3 Months"
        case .year: "This Year"
        case .allTime: "All Time"
        }
    }

    var daysBack: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .threeMonths: 90
        case .year: 365
        case .allTime: Int.max
        }
    }
}

struct ProgressOverviewView: View {
    @State private var selectedTimeframe: TimeframeFilter = .week

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header with title and timeframe selector
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Progress & Analytics")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Spacer()

                        Menu(self.selectedTimeframe.displayName) {
                            ForEach(TimeframeFilter.allCases, id: \.self) { timeframe in
                                Button(timeframe.displayName) {
                                    self.selectedTimeframe = timeframe
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    Text("Track your Swift learning journey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Study Streak Card
                StudyStreakCard()
                    .padding(.horizontal)

                // Quick Stats Row
                QuickStatsRow(timeframe: self.selectedTimeframe)
                    .padding(.horizontal)

                // Performance Trends Chart
                NavigationLink(destination: PerformanceTrendsView()) {
                    PerformanceTrendsSummary(timeframe: self.selectedTimeframe)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)

                // Category Performance Grid
                NavigationLink(destination: CategoryBreakdownView()) {
                    CategoryPerformanceGrid()
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)

                // Recent Badges
                NavigationLink(destination: BadgeCollectionView()) {
                    RecentBadgesCard()
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)

                // Study Insights
                NavigationLink(destination: StudyInsightsView()) {
                    StudyInsightsSummary()
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .sqNavigationBarHidden(true)
        .refreshable {
            // Refresh analytics data
            await self.refreshAnalytics()
        }
    }

    private func refreshAnalytics() async {
        // Simulate refresh delay
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

#Preview {
    ProgressOverviewView()
}
