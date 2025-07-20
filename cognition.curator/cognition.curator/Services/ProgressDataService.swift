import Foundation
import Combine
import SwiftUI

// MARK: - Progress Data Models

struct ProgressData {
    let currentStreak: Int
    let totalCardsReviewed: Int
    let averageAccuracy: Double
    let studyTimeMinutes: Int
    let cardsDueToday: Int
    let weeklyProgress: WeeklyProgress
    let dailyStats: [DailyProgress]
    let recentActivities: [RecentActivity]
    let topDecks: [DeckProgress]
}

struct WeeklyProgress {
    let totalMinutes: Int
    let totalCards: Int
    let averageAccuracy: Double
    let sessionCount: Int
}

struct DailyProgress {
    let date: Date
    let studyMinutes: Int
    let cardsReviewed: Int
    let accuracyRate: Double
}

struct RecentActivity {
    let type: ActivityType
    let title: String
    let time: Date
    let count: Int?
}

struct DeckProgress {
    let id: String
    let name: String
    let totalCards: Int
    let masteryRate: Double
    let accuracyRate: Double
    let studyTimeMinutes: Int
}

// MARK: - Progress Data Service

@MainActor
class ProgressDataService: ObservableObject {
    static let shared = ProgressDataService()

    @Published var progressData: ProgressData?
    @Published var isLoading = false
    @Published var error: String?

    private let analyticsService = AnalyticsAPIService.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {}

        func loadProgressData(timeframe: Timeframe = .week) {
        print("🔄 ProgressDataService: Starting to load progress data...")
        print("🔐 ProgressDataService: Authentication status: \(AuthenticationService.shared.isAuthenticated)")

        guard AuthenticationService.shared.isAuthenticated else {
            print("❌ ProgressDataService: User not authenticated")
            self.error = "Not authenticated"
            return
        }

        print("✅ ProgressDataService: User authenticated, proceeding with API call")
        isLoading = true
        error = nil

        let days = timeframe == .week ? 7 : (timeframe == .month ? 30 : 365)
        print("📊 ProgressDataService: Requesting \(days) days of data for timeframe: \(timeframe.displayName)")
        print("🔄 ProgressDataService: Making fresh API call to backend (not using cached data)")

        analyticsService.getDashboard(days: days)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    print("🏁 ProgressDataService: API call completed")
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ ProgressDataService: API error: \(error.localizedDescription)")
                        print("🔧 ProgressDataService: Full error: \(error)")
                        self?.error = error.localizedDescription
                        self?.loadMockDataAsFallback() // Fallback to mock data if API fails
                    }
                },
                receiveValue: { [weak self] dashboard in
                    print("✅ ProgressDataService: Successfully received dashboard data")
                    print("📈 ProgressDataService: User stats - Streak: \(dashboard.userStats.currentStreakDays), Cards: \(dashboard.userStats.totalCardsReviewed)")
                    self?.isLoading = false
                    self?.progressData = self?.mapDashboardToProgressData(dashboard)
                    print("💾 ProgressDataService: Progress data mapped and stored")
                }
            )
            .store(in: &cancellables)
    }

    private func mapDashboardToProgressData(_ dashboard: AnalyticsDashboard) -> ProgressData {
        let dateFormatter = ISO8601DateFormatter()

        // Map daily stats
        let dailyStats = dashboard.dailyChartData.compactMap { dayStats -> DailyProgress? in
            guard let date = dateFormatter.date(from: dayStats.date) else { return nil }
            return DailyProgress(
                date: date,
                studyMinutes: dayStats.studyMinutes,
                cardsReviewed: dayStats.cardsReviewed,
                accuracyRate: dayStats.accuracyRate
            )
        }

        // Map recent activities from study sessions
        let recentActivities = dashboard.recentSessions.prefix(5).map { session -> RecentActivity in
            let sessionDate = dateFormatter.date(from: session.startedAt) ?? Date()
            return RecentActivity(
                type: .review,
                title: "Reviewed \(session.cardsReviewed) cards",
                time: sessionDate,
                count: session.cardsReviewed
            )
        }

        // Map deck progress
        let topDecks = dashboard.topDecks.map { deck in
            DeckProgress(
                id: deck.id,
                name: deck.name,
                totalCards: deck.totalCards,
                masteryRate: deck.masteryRate,
                accuracyRate: deck.accuracyRate,
                studyTimeMinutes: deck.studyTimeMinutes
            )
        }

        return ProgressData(
            currentStreak: dashboard.userStats.currentStreakDays,
            totalCardsReviewed: dashboard.userStats.totalCardsReviewed,
            averageAccuracy: dashboard.userStats.overallAccuracyRate,
            studyTimeMinutes: dashboard.userStats.totalStudyTimeMinutes,
            cardsDueToday: dashboard.cardsDueToday,
            weeklyProgress: WeeklyProgress(
                totalMinutes: dashboard.weeklySummary.totalMinutes,
                totalCards: dashboard.weeklySummary.totalCards,
                averageAccuracy: dashboard.weeklySummary.averageAccuracy,
                sessionCount: dashboard.weeklySummary.sessionCount
            ),
            dailyStats: dailyStats,
            recentActivities: Array(recentActivities),
            topDecks: topDecks
        )
    }

        private func loadMockDataAsFallback() {
        print("🎭 ProgressDataService: Loading mock data as fallback")
        // Fallback mock data if API fails
        let mockDailyStats = (0..<7).map { dayOffset in
            DailyProgress(
                date: Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date(),
                studyMinutes: Int.random(in: 10...60),
                cardsReviewed: Int.random(in: 5...50),
                accuracyRate: Double.random(in: 0.7...0.95)
            )
        }.reversed()

        let mockActivities = [
            RecentActivity(type: .review, title: "Reviewed Biology deck", time: Date(), count: 25),
            RecentActivity(type: .create, title: "Created new card", time: Date().addingTimeInterval(-3600), count: nil),
            RecentActivity(type: .review, title: "Reviewed Math deck", time: Date().addingTimeInterval(-7200), count: 15)
        ]

        progressData = ProgressData(
            currentStreak: 7,
            totalCardsReviewed: 156,
            averageAccuracy: 0.85,
            studyTimeMinutes: 45,
            cardsDueToday: 12,
            weeklyProgress: WeeklyProgress(
                totalMinutes: 180,
                totalCards: 85,
                averageAccuracy: 0.87,
                sessionCount: 5
            ),
            dailyStats: Array(mockDailyStats),
            recentActivities: mockActivities,
            topDecks: []
        )
        print("✅ ProgressDataService: Mock data loaded successfully")
    }

    func refresh() {
        loadProgressData()
    }
}