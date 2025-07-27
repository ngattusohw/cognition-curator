import SwiftUI
import UIKit
import CoreData
import Combine

struct ProgressStatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var progressDataService = ProgressDataService.shared
    @StateObject private var offlineProgressService = OfflineProgressService.shared
    @StateObject private var offlineSyncService = OfflineSyncService.shared
    @State private var selectedTimeframe: Timeframe = .week
    @Binding var selectedTab: Int

    // MARK: - Computed Properties for Offline-First Data

    private var currentProgressData: LocalProgressData? {
        // Use offline data as primary source, fallback to online data converted to local format
        if let localData = offlineProgressService.localProgressData {
            return localData
        } else if let onlineData = progressDataService.progressData {
            // Convert online data to local format
            return LocalProgressData(
                currentStreak: onlineData.currentStreak,
                longestStreak: onlineData.currentStreak, // Simplified
                totalCardsReviewed: onlineData.totalCardsReviewed,
                totalStudyTimeMinutes: onlineData.studyTimeMinutes,
                overallAccuracyRate: onlineData.averageAccuracy,
                cardsDueToday: onlineData.cardsDueToday,
                recentSessions: [], // Would need conversion
                weeklyStats: [], // Would need conversion
                topDecks: [], // Would need conversion
                studyInsights: [],
                lastUpdated: Date(),
                isOfflineCalculated: false,
                pendingSyncCount: offlineSyncService.pendingOperationsCount
            )
        }
        return nil
    }

    private var streakDisplayValue: String {
        let streak = currentProgressData?.currentStreak ?? 0
        if streak == 0 {
            return "Start today!"
        } else {
            return "\(streak) day\(streak == 1 ? "" : "s")"
        }
    }

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
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh when app comes to foreground
                progressDataService.refresh()
                offlineProgressService.refreshProgress()

                // Trigger sync if we have pending operations
                if offlineSyncService.pendingOperationsCount > 0 {
                    Task {
                        await offlineSyncService.syncPendingOperations()
                    }
                }
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

            if progressDataService.isLoading || offlineProgressService.isCalculating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading \(selectedTimeframe.displayName.lowercased()) data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }

            // Offline/Sync Status Indicators
            HStack(spacing: 12) {
                if currentProgressData?.isOfflineCalculated == true {
                    HStack(spacing: 4) {
                        Image(systemName: "wifi.slash")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Offline Mode")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                if offlineSyncService.pendingOperationsCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "icloud.and.arrow.up")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("\(offlineSyncService.pendingOperationsCount) pending")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }

                if offlineSyncService.isSyncing {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Syncing...")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }

                Spacer()
            }
            .padding(.top, 4)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatOverviewCard(
                    title: "Cards Reviewed",
                    value: "\(currentProgressData?.totalCardsReviewed ?? 0)",
                    icon: "brain.head.profile",
                    color: .blue
                )

                StatOverviewCard(
                    title: "Accuracy",
                    value: "\(Int((currentProgressData?.overallAccuracyRate ?? 0.0) * 100))%",
                    icon: "target",
                    color: .green
                )

                StatOverviewCard(
                    title: "Study Time",
                    value: "\(currentProgressData?.totalStudyTimeMinutes ?? 0)m",
                    icon: "clock.fill",
                    color: .orange
                )

                StatOverviewCard(
                    title: "Streak",
                    value: streakDisplayValue,
                    icon: "flame.fill",
                    color: currentProgressData?.currentStreak == 0 ? .gray : .red
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

                    Text("\(currentProgressData?.cardsDueToday ?? 0) cards waiting for review")
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
                // Daily activity chart with real data
                DailyActivityChart(dailyStats: combinedDailyStats)

                // Accuracy trend chart with real data
                AccuracyTrendChart(dailyStats: combinedDailyStats)
            }
        }
    }

    // MARK: - Unified Data Access

    private var combinedDailyStats: [DailyProgress] {
        // First try to use offline data (which uses LocalDayStats)
        if let localData = offlineProgressService.localProgressData {
            return localData.weeklyStats.map { localStat in
                DailyProgress(
                    date: localStat.date,
                    studyMinutes: localStat.studyMinutes,
                    cardsReviewed: localStat.cardsReviewed,
                    accuracyRate: localStat.accuracyRate
                )
            }
        }
        // Fallback to online data
        else if let onlineData = progressDataService.progressData {
            return onlineData.dailyStats
        }
        // No data available
        return []
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
                let activities = combinedRecentActivities
                if !activities.isEmpty {
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

    // MARK: - Enhanced Recent Activities

    private var combinedRecentActivities: [RecentActivity] {
        var activities: [RecentActivity] = []

        // First try to get activities from online data
        if let onlineActivities = progressDataService.progressData?.recentActivities {
            activities.append(contentsOf: onlineActivities)
        }

        // Add activities from offline/local data
        activities.append(contentsOf: generateLocalActivities())

        // Sort by time and take the most recent 10
        return Array(activities.sorted { $0.time > $1.time }.prefix(10))
    }

    private func generateLocalActivities() -> [RecentActivity] {
        var activities: [RecentActivity] = []
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()

        // Recent review sessions from Core Data
        let reviewRequest: NSFetchRequest<ReviewSession> = ReviewSession.fetchRequest()
        reviewRequest.predicate = NSPredicate(format: "reviewedAt >= %@", twoDaysAgo as NSDate)
        reviewRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ReviewSession.reviewedAt, ascending: false)]
        reviewRequest.fetchLimit = 10

        do {
            let recentReviews = try viewContext.fetch(reviewRequest)
            let reviewGroups = Dictionary(grouping: recentReviews) { review in
                calendar.startOfDay(for: review.reviewedAt ?? Date())
            }

            for (date, reviews) in reviewGroups.prefix(5) {
                let cardCount = reviews.count
                let deckNames = Set(reviews.compactMap { $0.flashcard?.deck?.name }).joined(separator: ", ")

                activities.append(RecentActivity(
                    type: .review,
                    title: cardCount == 1 ?
                        "Reviewed 1 card\(deckNames.isEmpty ? "" : " from \(deckNames)")" :
                        "Reviewed \(cardCount) cards\(deckNames.isEmpty ? "" : " from \(deckNames)")",
                    time: reviews.first?.reviewedAt ?? date,
                    count: cardCount
                ))
            }
        } catch {
            print("❌ Error fetching recent reviews: \(error)")
        }

        // Recent deck creations
        let deckRequest: NSFetchRequest<Deck> = Deck.fetchRequest()
        deckRequest.predicate = NSPredicate(format: "createdAt >= %@", twoDaysAgo as NSDate)
        deckRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Deck.createdAt, ascending: false)]
        deckRequest.fetchLimit = 5

        do {
            let recentDecks = try viewContext.fetch(deckRequest)
            for deck in recentDecks {
                activities.append(RecentActivity(
                    type: .deckCreated,
                    title: "Created deck '\(deck.name ?? "Unknown")'",
                    time: deck.createdAt ?? Date(),
                    count: nil
                ))
            }
        } catch {
            print("❌ Error fetching recent decks: \(error)")
        }

        // Recent card additions
        let cardRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        cardRequest.predicate = NSPredicate(format: "createdAt >= %@", twoDaysAgo as NSDate)
        cardRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Flashcard.createdAt, ascending: false)]
        cardRequest.fetchLimit = 20

        do {
            let recentCards = try viewContext.fetch(cardRequest)

            // Group cards by date and deck name
            struct CardGroupKey: Hashable {
                let date: Date
                let deckName: String
            }

            let cardGroups = Dictionary(grouping: recentCards) { card in
                CardGroupKey(
                    date: calendar.startOfDay(for: card.createdAt ?? Date()),
                    deckName: card.deck?.name ?? "Unknown"
                )
            }

            for (groupKey, cards) in cardGroups.prefix(3) {
                let cardCount = cards.count
                activities.append(RecentActivity(
                    type: .cardAdded,
                    title: cardCount == 1 ?
                        "Added 1 card to \(groupKey.deckName)" :
                        "Added \(cardCount) cards to \(groupKey.deckName)",
                    time: cards.first?.createdAt ?? groupKey.date,
                    count: cardCount
                ))
            }
        } catch {
            print("❌ Error fetching recent cards: \(error)")
        }

        // Check for streak achievements
        if let streak = currentProgressData?.currentStreak, streak > 0 {
            // Add streak activity if it's a milestone (every 7 days)
            if streak % 7 == 0 && streak <= 30 {
                activities.append(RecentActivity(
                    type: .streakAchieved,
                    title: "Achieved \(streak)-day streak! 🎉",
                    time: Date(),
                    count: streak
                ))
            }
        }

        return activities
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
    let dailyStats: [DailyProgress]

    private var chartData: [(String, Int, Int)] {
        let calendar = Calendar.current
        let today = Date()

        // Get last 7 days
        let last7Days = (0..<7).compactMap { daysBack in
            calendar.date(byAdding: .day, value: -daysBack, to: today)
        }.reversed()

        return last7Days.map { date in
            let dayLabel = DateFormatter().weekdaySymbols[calendar.component(.weekday, from: date) - 1].prefix(1).uppercased()

            // Find matching daily stat
            if let stat = dailyStats.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                return (String(dayLabel), stat.studyMinutes, stat.cardsReviewed)
            } else {
                return (String(dayLabel), 0, 0)
            }
        }
    }

    private var maxStudyMinutes: Int {
        max(chartData.map { $0.1 }.max() ?? 1, 10) // Minimum height for visibility
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Activity")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("Study Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(chartData.enumerated()), id: \.offset) { index, data in
                    let (dayLabel, studyMinutes, cardsReviewed) = data

                    VStack(spacing: 4) {
                        // Bar representing study minutes
                        RoundedRectangle(cornerRadius: 4)
                            .fill(studyMinutes > 0 ? Color.blue.opacity(0.8) : Color.gray.opacity(0.3))
                            .frame(height: max(CGFloat(studyMinutes) / CGFloat(maxStudyMinutes) * 80, 4))

                        // Day label
                        Text(dayLabel)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        // Could show a tooltip or details
                        print("📊 Day: \(dayLabel), Study: \(studyMinutes)min, Cards: \(cardsReviewed)")
                    }
                }
            }
            .frame(height: 100)

            // Summary stats
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("7-Day Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(chartData.map { $0.1 }.reduce(0, +))min")
                        .font(.caption)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Cards Reviewed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(chartData.map { $0.2 }.reduce(0, +))")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct AccuracyTrendChart: View {
    let dailyStats: [DailyProgress]

    private var chartData: [(String, Double)] {
        let calendar = Calendar.current
        let today = Date()

        // Get last 7 days
        let last7Days = (0..<7).compactMap { daysBack in
            calendar.date(byAdding: .day, value: -daysBack, to: today)
        }.reversed()

        return last7Days.map { date in
            let dayLabel = DateFormatter().weekdaySymbols[calendar.component(.weekday, from: date) - 1].prefix(1).uppercased()

            // Find matching daily stat
            if let stat = dailyStats.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                return (String(dayLabel), stat.accuracyRate)
            } else {
                return (String(dayLabel), 0.0)
            }
        }
    }

    private var averageAccuracy: Double {
        let validAccuracies = chartData.compactMap { $0.1 > 0 ? $0.1 : nil }
        return validAccuracies.isEmpty ? 0 : validAccuracies.reduce(0, +) / Double(validAccuracies.count)
    }

    private var accuracyTrend: String {
        let validData = chartData.compactMap { $0.1 > 0 ? $0.1 : nil }
        guard validData.count >= 2 else { return "No data" }

        let recent = Array(validData.suffix(3))
        let older = Array(validData.prefix(max(validData.count - 3, 1)))

        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg = older.reduce(0, +) / Double(older.count)

        if recentAvg > olderAvg + 0.05 {
            return "Improving"
        } else if recentAvg < olderAvg - 0.05 {
            return "Declining"
        } else {
            return "Stable"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Accuracy Trend")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text(accuracyTrend)
                    .font(.caption)
                    .foregroundColor(accuracyTrend == "Improving" ? .green :
                                   accuracyTrend == "Declining" ? .red : .secondary)
                    .fontWeight(.medium)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(chartData.enumerated()), id: \.offset) { index, data in
                    let (dayLabel, accuracy) = data
                    let hasData = accuracy > 0
                    let heightRatio = hasData ? accuracy : 0.1 // Minimum height for no-data days

                    VStack(spacing: 4) {
                        // Bar representing accuracy rate
                        RoundedRectangle(cornerRadius: 4)
                            .fill(hasData ? accuracyColor(for: accuracy) : Color.gray.opacity(0.3))
                            .frame(height: max(CGFloat(heightRatio) * 80, 4))

                        // Day label
                        Text(dayLabel)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        print("📊 Day: \(dayLabel), Accuracy: \(hasData ? "\(Int(accuracy * 100))%" : "No data")")
                    }
                }
            }
            .frame(height: 100)

            // Summary stats
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("7-Day Average")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(averageAccuracy * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(accuracyColor(for: averageAccuracy))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Study Days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(chartData.filter { $0.1 > 0 }.count)/7")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func accuracyColor(for accuracy: Double) -> Color {
        switch accuracy {
        case 0.9...: return .green
        case 0.8..<0.9: return .blue
        case 0.7..<0.8: return .orange
        default: return .red
        }
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
    case review
    case create
    case deckCreated
    case cardAdded
    case aiGenerated
    case streakAchieved
    case study
    case practice

    var icon: String {
        switch self {
        case .review: return "brain.head.profile"
        case .create: return "plus.circle"
        case .deckCreated: return "rectangle.stack.badge.plus"
        case .cardAdded: return "plus.rectangle.on.rectangle"
        case .aiGenerated: return "wand.and.stars"
        case .streakAchieved: return "flame.fill"
        case .study: return "book.fill"
        case .practice: return "repeat.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .review: return .blue
        case .create: return .green
        case .deckCreated: return .purple
        case .cardAdded: return .green
        case .aiGenerated: return .orange
        case .streakAchieved: return .red
        case .study: return .blue
        case .practice: return .cyan
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
