// Analytics API Service for syncing with backend analytics system.

import Foundation
import Combine

// MARK: - API Models

struct AnalyticsDashboard: Codable {
    let userStats: UserStats
    let cardsDueToday: Int
    let recentSessions: [StudySessionResponse]
    let dailyChartData: [DayStatsResponse]
    let topDecks: [DeckStatsResponse]
    let weeklySummary: WeeklySummaryResponse
    let insights: [InsightResponse]

    enum CodingKeys: String, CodingKey {
        case userStats = "user_stats"
        case cardsDueToday = "cards_due_today"
        case recentSessions = "recent_sessions"
        case dailyChartData = "daily_chart_data"
        case topDecks = "top_decks"
        case weeklySummary = "weekly_summary"
        case insights
    }
}

struct UserStats: Codable {
    let totalStudyTimeMinutes: Int
    let currentStreakDays: Int
    let longestStreakDays: Int
    let totalCardsReviewed: Int
    let totalDecksCreated: Int
    let overallAccuracyRate: Double
    let studyLevel: Int
    let levelProgress: Double
    let masteryRate: Double

    enum CodingKeys: String, CodingKey {
        case totalStudyTimeMinutes = "total_study_time_minutes"
        case currentStreakDays = "current_streak_days"
        case longestStreakDays = "longest_streak_days"
        case totalCardsReviewed = "total_cards_reviewed"
        case totalDecksCreated = "total_decks_created"
        case overallAccuracyRate = "overall_accuracy_rate"
        case studyLevel = "study_level"
        case levelProgress = "level_progress"
        case masteryRate = "mastery_rate"
    }
}

struct StudySessionResponse: Codable {
    let id: String
    let sessionType: String
    let durationMinutes: Int
    let cardsReviewed: Int
    let accuracyRate: Double
    let sessionQualityScore: Double
    let startedAt: String
    let platform: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionType = "session_type"
        case durationMinutes = "duration_minutes"
        case cardsReviewed = "cards_reviewed"
        case accuracyRate = "accuracy_rate"
        case sessionQualityScore = "session_quality_score"
        case startedAt = "started_at"
        case platform
    }
}

struct DayStatsResponse: Codable {
    let date: String
    let studyMinutes: Int
    let cardsReviewed: Int
    let accuracyRate: Double

    enum CodingKeys: String, CodingKey {
        case date
        case studyMinutes = "study_minutes"
        case cardsReviewed = "cards_reviewed"
        case accuracyRate = "accuracy_rate"
    }
}

struct DeckStatsResponse: Codable {
    let id: String
    let name: String
    let totalCards: Int
    let masteryRate: Double
    let accuracyRate: Double
    let studyTimeMinutes: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case totalCards = "total_cards"
        case masteryRate = "mastery_rate"
        case accuracyRate = "accuracy_rate"
        case studyTimeMinutes = "study_time_minutes"
    }
}

struct WeeklySummaryResponse: Codable {
    let totalMinutes: Int
    let totalCards: Int
    let averageAccuracy: Double
    let sessionCount: Int

    enum CodingKeys: String, CodingKey {
        case totalMinutes = "total_minutes"
        case totalCards = "total_cards"
        case averageAccuracy = "average_accuracy"
        case sessionCount = "session_count"
    }
}

struct InsightResponse: Codable {
    let id: String
    let title: String
    let description: String
    let category: String
    let priority: String
}

struct StudySessionSync: Codable {
    let deckId: String?
    let sessionType: String
    let startedAt: String
    let endedAt: String?
    let durationMinutes: Int
    let cardsReviewed: Int
    let cardsCorrect: Int
    let cardsIncorrect: Int
    let accuracyRate: Double
    let deviceType: String
    let appVersion: String?
}

// MARK: - Analytics API Service

class AnalyticsAPIService: ObservableObject {
    static let shared = AnalyticsAPIService()

    private let baseURL = "http://127.0.0.1:5001/api"  // Updated to use 127.0.0.1 for iOS Simulator
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    // MARK: - Dashboard Data

    func getDashboard(days: Int = 30) -> AnyPublisher<AnalyticsDashboard, Error> {
        print("🌐 AnalyticsAPIService: Starting getDashboard request")

        guard let url = URL(string: "\(baseURL)/analytics/dashboard?days=\(days)") else {
            print("❌ AnalyticsAPIService: Invalid URL: \(baseURL)/analytics/dashboard?days=\(days)")
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }

        print("🔗 AnalyticsAPIService: URL created: \(url)")

        // Use authenticated request from AuthenticationService
        guard let request = AuthenticationService.shared.createAuthenticatedRequest(url: url, method: "GET") else {
            print("❌ AnalyticsAPIService: Failed to create authenticated request")
            return Fail(error: URLError(.userAuthenticationRequired))
                .eraseToAnyPublisher()
        }

        print("🔐 AnalyticsAPIService: Authenticated request created")
        if let authHeader = request.value(forHTTPHeaderField: "Authorization") {
            print("🎫 AnalyticsAPIService: Authorization header: \(String(authHeader.prefix(20)))...")
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .handleEvents(
                receiveSubscription: { _ in
                    print("📡 AnalyticsAPIService: Starting network request...")
                },
                receiveOutput: { data, response in
                    print("📥 AnalyticsAPIService: Received response")
                    if let httpResponse = response as? HTTPURLResponse {
                        print("📊 AnalyticsAPIService: Status code: \(httpResponse.statusCode)")
                    }
                    print("📦 AnalyticsAPIService: Data size: \(data.count) bytes")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📄 AnalyticsAPIService: Response preview: \(String(responseString.prefix(200)))...")
                    }
                },
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ AnalyticsAPIService: Network error: \(error)")
                    } else {
                        print("✅ AnalyticsAPIService: Request completed successfully")
                    }
                }
            )
            .map(\.data)
            .decode(type: AnalyticsDashboard.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Sync Study Session

    func syncStudySession(_ session: StudySessionSync) -> AnyPublisher<Bool, Error> {
        guard let url = URL(string: "\(baseURL)/sync/study-session") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }

        // Use authenticated request from AuthenticationService
        guard var request = AuthenticationService.shared.createAuthenticatedRequest(url: url, method: "POST") else {
            return Fail(error: URLError(.userAuthenticationRequired))
                .eraseToAnyPublisher()
        }

        do {
            request.httpBody = try JSONEncoder().encode(session)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .map { _ in true }
            .catch { error in
                print("Failed to sync study session: \(error)")
                return Just(false)
                    .setFailureType(to: Error.self)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Sync User Stats

    func syncUserStats(streakDays: Int, cardsReviewed: Int, studyTime: Int) -> AnyPublisher<Bool, Error> {
        guard let url = URL(string: "\(baseURL)/sync/user-stats") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }

        let syncData = [
            "current_streak_days": streakDays,
            "total_cards_reviewed": cardsReviewed,
            "total_study_time_minutes": studyTime
        ]

        // Use authenticated request from AuthenticationService
        guard var request = AuthenticationService.shared.createAuthenticatedRequest(url: url, method: "POST") else {
            return Fail(error: URLError(.userAuthenticationRequired))
                .eraseToAnyPublisher()
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: syncData)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .map { _ in true }
            .catch { error in
                print("Failed to sync user stats: \(error)")
                return Just(false)
                    .setFailureType(to: Error.self)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }


    // MARK: - Mock Data for Testing

    func getMockDashboard() -> AnalyticsDashboard {
        return AnalyticsDashboard(
            userStats: UserStats(
                totalStudyTimeMinutes: 450,
                currentStreakDays: 7,
                longestStreakDays: 21,
                totalCardsReviewed: 234,
                totalDecksCreated: 3,
                overallAccuracyRate: 0.847,
                studyLevel: 3,
                levelProgress: 0.67,
                masteryRate: 0.423
            ),
            cardsDueToday: 12,
            recentSessions: [
                StudySessionResponse(
                    id: "1",
                    sessionType: "regular",
                    durationMinutes: 25,
                    cardsReviewed: 18,
                    accuracyRate: 0.89,
                    sessionQualityScore: 0.85,
                    startedAt: "2024-01-15T10:30:00Z",
                    platform: "iOS"
                ),
                StudySessionResponse(
                    id: "2",
                    sessionType: "review",
                    durationMinutes: 15,
                    cardsReviewed: 12,
                    accuracyRate: 0.75,
                    sessionQualityScore: 0.72,
                    startedAt: "2024-01-14T16:45:00Z",
                    platform: "iOS"
                )
            ],
            dailyChartData: [
                DayStatsResponse(date: "2024-01-10", studyMinutes: 30, cardsReviewed: 24, accuracyRate: 0.83),
                DayStatsResponse(date: "2024-01-11", studyMinutes: 45, cardsReviewed: 36, accuracyRate: 0.89),
                DayStatsResponse(date: "2024-01-12", studyMinutes: 20, cardsReviewed: 15, accuracyRate: 0.80),
                DayStatsResponse(date: "2024-01-13", studyMinutes: 35, cardsReviewed: 28, accuracyRate: 0.86),
                DayStatsResponse(date: "2024-01-14", studyMinutes: 25, cardsReviewed: 20, accuracyRate: 0.75),
                DayStatsResponse(date: "2024-01-15", studyMinutes: 40, cardsReviewed: 32, accuracyRate: 0.91)
            ],
            topDecks: [
                DeckStatsResponse(
                    id: "deck1",
                    name: "Spanish Vocabulary",
                    totalCards: 120,
                    masteryRate: 0.65,
                    accuracyRate: 0.87,
                    studyTimeMinutes: 180
                ),
                DeckStatsResponse(
                    id: "deck2",
                    name: "Medical Terms",
                    totalCards: 89,
                    masteryRate: 0.45,
                    accuracyRate: 0.82,
                    studyTimeMinutes: 145
                )
            ],
            weeklySummary: WeeklySummaryResponse(
                totalMinutes: 195,
                totalCards: 155,
                averageAccuracy: 0.847,
                sessionCount: 7
            ),
            insights: [
                InsightResponse(
                    id: "insight1",
                    title: "Great consistency!",
                    description: "You've studied 7 days in a row. Keep up the excellent work!",
                    category: "motivation",
                    priority: "high"
                ),
                InsightResponse(
                    id: "insight2",
                    title: "Morning sessions perform better",
                    description: "Your accuracy is 12% higher in morning study sessions.",
                    category: "study_habits",
                    priority: "medium"
                )
            ]
        )
    }
}
