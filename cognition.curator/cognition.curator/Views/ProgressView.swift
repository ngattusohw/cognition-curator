import SwiftUI
import UIKit
import CoreData
import Combine

struct ProgressStatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var progressDataService = ProgressDataService.shared
    @State private var selectedTimeframe: Timeframe = .week
    @Binding var selectedTab: Int

    var body: some View {
                NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Loading state
                    if progressDataService.isLoading {
                        ProgressView("Loading your progress...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    }
                    // Error state
                    else if let error = progressDataService.error {
                        ErrorView(error: error) {
                            progressDataService.refresh()
                        }
                    }
                    // Content
                    else {
                        // Stats overview
                        statsOverview

                        // Cards due today
                        if let cardsDue = progressDataService.progressData?.cardsDueToday, cardsDue > 0 {
                            cardsDueTodayCard
                        }

                        // Streak card
                        streakCard

                        // Charts section
                        chartsSection

                        // Recent activity
                        recentActivitySection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(uiColor: UIColor.systemGroupedBackground))
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                progressDataService.refresh()
            }
            .onAppear {
                progressDataService.loadProgressData(timeframe: selectedTimeframe)
            }
            .onChange(of: selectedTimeframe) { _, newTimeframe in
                progressDataService.loadProgressData(timeframe: newTimeframe)
            }
        }
    }

        private var statsOverview: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Overview")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(Timeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.displayName).tag(timeframe)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
                .disabled(progressDataService.isLoading)
                .opacity(progressDataService.isLoading ? 0.6 : 1.0)
            }

            if progressDataService.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading \(selectedTimeframe.displayName.lowercased()) data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatOverviewCard(
                    title: "Cards Reviewed",
                    value: "\(progressDataService.progressData?.totalCardsReviewed ?? 0)",
                    icon: "brain.head.profile",
                    color: .blue
                )

                StatOverviewCard(
                    title: "Accuracy",
                    value: "\(Int((progressDataService.progressData?.averageAccuracy ?? 0.0) * 100))%",
                    icon: "target",
                    color: .green
                )

                StatOverviewCard(
                    title: "Study Time",
                    value: "\(progressDataService.progressData?.studyTimeMinutes ?? 0)m",
                    icon: "clock.fill",
                    color: .orange
                )

                StatOverviewCard(
                    title: "Streak",
                    value: "\(progressDataService.progressData?.currentStreak ?? 0) days",
                    icon: "flame.fill",
                    color: .red
                )
            }
        }
    }

            private var cardsDueTodayCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.title2)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Cards Due Today")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("\(progressDataService.progressData?.cardsDueToday ?? 0) cards waiting for review")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Review Now") {
                    print("🎯 ProgressView: Navigating to review tab")
                    selectedTab = 2 // Review tab
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var streakCard: some View {
        let currentStreak = progressDataService.progressData?.currentStreak ?? 0
        let isZeroStreak = currentStreak == 0

        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(isZeroStreak ? "Start your learning journey today!" : "Keep it up! Consistency is key to learning.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(spacing: 4) {
                    if isZeroStreak {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                    } else {
                        Text("\(currentStreak)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.orange)

                        Text("days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Streak visualization
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    Circle()
                        .fill(day < min(currentStreak, 7) ? Color.orange : Color(uiColor: UIColor.systemGray5))
                        .frame(width: 12, height: 12)
                }
            }

            // Call to action for zero streak
            if isZeroStreak {
                Button("Start Learning") {
                    print("🎯 ProgressView: Starting learning journey, navigating to review tab")
                    selectedTab = 2 // Review tab
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var chartsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Learning Trends")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()
            }

            VStack(spacing: 20) {
                // Daily activity chart
                DailyActivityChart()

                // Accuracy trend chart
                AccuracyTrendChart()
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()
            }

            LazyVStack(spacing: 12) {
                if let activities = progressDataService.progressData?.recentActivities, !activities.isEmpty {
                    ForEach(activities.indices, id: \.self) { index in
                        ActivityRowView(activity: activities[index])
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "clock.badge")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("No recent activity")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 60)
                }
            }
        }
    }


}

struct StatOverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct DailyActivityChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Activity")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.7))
                            .frame(height: CGFloat.random(in: 20...80))

                        Text(["M", "T", "W", "T", "F", "S", "S"][day])
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(20)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct AccuracyTrendChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accuracy Trend")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.opacity(0.7))
                            .frame(height: CGFloat.random(in: 30...60))

                        Text(["M", "T", "W", "T", "F", "S", "S"][day])
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(20)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct ActivityRowView: View {
    let activity: RecentActivity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.type.icon)
                .font(.title3)
                .foregroundColor(activity.type.color)
                .frame(width: 32, height: 32)
                .background(activity.type.color.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(formatTime(activity.time))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let count = activity.count {
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }


}

enum Timeframe: CaseIterable {
    case week, month, year

    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
}

enum ActivityType {
    case review, create

    var icon: String {
        switch self {
        case .review: return "brain.head.profile"
        case .create: return "plus.circle"
        }
    }

    var color: Color {
        switch self {
        case .review: return .blue
        case .create: return .green
        }
    }
}



// MARK: - Error View

struct ErrorView: View {
    let error: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to load progress")
                .font(.headline)
                .fontWeight(.semibold)

            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Try Again") {
                retry()
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
}

#Preview {
    ProgressStatsView(selectedTab: .constant(3))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
