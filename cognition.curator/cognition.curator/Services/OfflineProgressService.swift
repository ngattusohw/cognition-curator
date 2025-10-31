import Foundation
import SwiftData
import Combine

// MARK: - Local Progress Models

struct LocalProgressData {
    let currentStreak: Int
    let longestStreak: Int
    let totalCardsReviewed: Int
    let totalStudyTimeMinutes: Int
    let overallAccuracyRate: Double
    let cardsDueToday: Int
    let recentSessions: [LocalSessionSummary]
    let weeklyStats: [LocalDayStats]
    let topDecks: [LocalDeckStats]
    let studyInsights: [String]
    let lastUpdated: Date

    // Offline-specific properties
    let isOfflineCalculated: Bool
    let pendingSyncCount: Int
}

struct LocalSessionSummary {
    let id: String
    let date: Date
    let duration: Int
    let cardsReviewed: Int
    let accuracy: Double
    let deckName: String?
    let isSynced: Bool
}

struct LocalDayStats {
    let date: Date
    let studyMinutes: Int
    let cardsReviewed: Int
    let accuracyRate: Double
    let sessionCount: Int
}

struct LocalDeckStats {
    let id: String
    let name: String
    let totalCards: Int
    let cardsReviewed: Int
    let accuracyRate: Double
    let studyTimeMinutes: Int
    let lastReviewDate: Date?
}

enum ProgressTimeframe {
    case week
    case month
    case year
}

// MARK: - Offline Progress Service

@MainActor
class OfflineProgressService: ObservableObject {
    static let shared = OfflineProgressService()

    @Published var localProgressData: LocalProgressData?
    @Published var isCalculating = false

    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        calculateLocalProgress()
    }
    
    func calculateLocalProgress() {
        guard !isCalculating else { return }
        
        isCalculating = true
        
        Task {
            let context = persistenceController.container.mainContext
            
            do {
                let progressData = try await calculateProgressData(in: context)
                
                await MainActor.run {
                    self.localProgressData = progressData
                    self.isCalculating = false
                    print("📊 OfflineProgressService: Local progress calculated")
                }
            } catch {
                print("❌ OfflineProgressService: Failed to calculate progress: \(error)")
                await MainActor.run {
                    self.isCalculating = false
                }
            }
        }
    }
    
    private func calculateProgressData(in context: ModelContext) async throws -> LocalProgressData {
        // Calculate streak
        let streak = await calculateCurrentStreak(in: context)
        let longestStreak = await calculateLongestStreak(in: context)
        
        // Calculate total cards reviewed
        let totalCardsReviewed = try await calculateTotalCardsReviewed(in: context)
        
        // Calculate total study time
        let totalStudyTime = try await calculateTotalStudyTime(in: context)
        
        // Calculate overall accuracy
        let accuracy = try await calculateOverallAccuracy(in: context)
        
        // Calculate cards due today
        let cardsDue = try await calculateCardsDueToday(in: context)
        
        // Get recent sessions
        let recentSessions = try await getRecentSessions(in: context)
        
        // Calculate weekly stats
        let weeklyStats = try await calculateWeeklyStats(in: context)
        
        // Get top decks
        let topDecks = try await getTopDecks(in: context)
        
        // Generate insights
        let insights = generateInsights(
            streak: streak,
            totalCards: totalCardsReviewed,
            accuracy: accuracy,
            recentSessions: recentSessions
        )
        
        // Count pending sync operations
        let pendingSyncCount = try await countPendingSyncOperations(in: context)
        
        return LocalProgressData(
            currentStreak: streak,
            longestStreak: longestStreak,
            totalCardsReviewed: totalCardsReviewed,
            totalStudyTimeMinutes: totalStudyTime,
            overallAccuracyRate: accuracy,
            cardsDueToday: cardsDue,
            recentSessions: recentSessions,
            weeklyStats: weeklyStats,
            topDecks: topDecks,
            studyInsights: insights,
            lastUpdated: Date(),
            isOfflineCalculated: !NetworkMonitor.shared.isConnected,
            pendingSyncCount: pendingSyncCount
        )
    }
    
    // MARK: - Calculation Methods
    
    private func calculateCurrentStreak(in context: ModelContext) async -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var currentStreak = 0
        var checkDate = today
        
        while true {
            let dayStart = checkDate
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            var descriptor = FetchDescriptor<ReviewSession>(
                predicate: #Predicate<ReviewSession> { session in
                    session.reviewedAt >= dayStart && session.reviewedAt < dayEnd
                }
            )
            descriptor.fetchLimit = 1
            
            do {
                let sessions = try context.fetch(descriptor)
                if sessions.isEmpty {
                    break
                } else {
                    currentStreak += 1
                    guard let prevDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = prevDate
                }
            } catch {
                print("❌ OfflineProgressService: Error calculating streak: \(error)")
                break
            }
        }
        
        return currentStreak
    }
    
    private func calculateLongestStreak(in context: ModelContext) async -> Int {
        // Simplified implementation - calculate longest consecutive streak
        let currentStreak = await calculateCurrentStreak(in: context)
        // For now, return current streak as longest (could be enhanced to track historical longest)
        return currentStreak
    }
    
    private func calculateTotalCardsReviewed(in context: ModelContext) async throws -> Int {
        let descriptor = FetchDescriptor<ReviewSession>()
        let sessions = try context.fetch(descriptor)
        return sessions.count
    }
    
    private func calculateTotalStudyTime(in context: ModelContext) async throws -> Int {
        // Estimate 30 seconds per review
        let totalReviews = try await calculateTotalCardsReviewed(in: context)
        return (totalReviews * 30) / 60 // Convert to minutes
    }
    
    private func calculateOverallAccuracy(in context: ModelContext) async throws -> Double {
        let descriptor = FetchDescriptor<ReviewSession>()
        let sessions = try context.fetch(descriptor)
        
        guard !sessions.isEmpty else { return 0.0 }
        
        let correctSessions = sessions.filter { $0.difficulty >= 3 } // Good or Easy
        return Double(correctSessions.count) / Double(sessions.count)
    }
    
    private func calculateCardsDueToday(in context: ModelContext) async throws -> Int {
        let now = Date()
        let descriptor = FetchDescriptor<Flashcard>()
        
        let allCards = try context.fetch(descriptor)
        
        // Get unique flashcards that are due
        let dueCards = allCards.filter { card in
            guard let sessions = card.reviewSessions, !sessions.isEmpty else { return false }
            return sessions.contains { ($0.nextReview ?? Date()) <= now }
        }
        
        return Set(dueCards.map { $0.id }).count
    }
    
    private func getRecentSessions(in context: ModelContext) async throws -> [LocalSessionSummary] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        var descriptor = FetchDescriptor<ReviewSession>(
            predicate: #Predicate<ReviewSession> { session in
                session.reviewedAt >= sevenDaysAgo
            },
            sortBy: [SortDescriptor(\.reviewedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        
        let sessions = try context.fetch(descriptor)
        
        return sessions.compactMap { session in
            let id = session.id.uuidString
            
            return LocalSessionSummary(
                id: id,
                date: session.reviewedAt,
                duration: 1, // Estimate 1 minute per session
                cardsReviewed: 1,
                accuracy: session.difficulty >= 3 ? 1.0 : 0.0,
                deckName: session.flashcard?.deck?.name,
                isSynced: session.syncStatus == "synced"
            )
        }
    }
    
    private func calculateWeeklyStats(in context: ModelContext) async throws -> [LocalDayStats] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyStats: [LocalDayStats] = []
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            var descriptor = FetchDescriptor<ReviewSession>(
                predicate: #Predicate<ReviewSession> { session in
                    session.reviewedAt >= dayStart && session.reviewedAt < dayEnd
                }
            )
            
            let sessions = try context.fetch(descriptor)
            let correctSessions = sessions.filter { $0.difficulty >= 3 }
            
            let dayStats = LocalDayStats(
                date: dayStart,
                studyMinutes: sessions.count / 2, // Estimate 30 seconds per review
                cardsReviewed: sessions.count,
                accuracyRate: sessions.isEmpty ? 0.0 : Double(correctSessions.count) / Double(sessions.count),
                sessionCount: sessions.count
            )
            
            weeklyStats.append(dayStats)
        }
        
        return weeklyStats.reversed() // Oldest first
    }
    
    private func getTopDecks(in context: ModelContext) async throws -> [LocalDeckStats] {
        let descriptor = FetchDescriptor<Deck>()
        let decks = try context.fetch(descriptor)
        
        return decks.compactMap { deck in
            let deckId = deck.id.uuidString
            let flashcards = deck.flashcards ?? []
            let allSessions = flashcards.flatMap { $0.reviewSessions ?? [] }
            let correctSessions = allSessions.filter { $0.difficulty >= 3 }
            
            return LocalDeckStats(
                id: deckId,
                name: deck.name,
                totalCards: flashcards.count,
                cardsReviewed: allSessions.count,
                accuracyRate: allSessions.isEmpty ? 0.0 : Double(correctSessions.count) / Double(allSessions.count),
                studyTimeMinutes: allSessions.count / 2, // Estimate
                lastReviewDate: allSessions.map { $0.reviewedAt }.max()
            )
        }
        .sorted { $0.cardsReviewed > $1.cardsReviewed }
        .prefix(5)
        .map { $0 }
    }
    
    private func generateInsights(
        streak: Int,
        totalCards: Int,
        accuracy: Double,
        recentSessions: [LocalSessionSummary]
    ) -> [String] {
        var insights: [String] = []
        
        if streak > 0 {
            insights.append("🔥 You're on a \(streak)-day study streak! Keep it up!")
        }
        
        if accuracy > 0.8 {
            insights.append("⭐ Excellent accuracy rate of \(Int(accuracy * 100))%!")
        } else if accuracy > 0.6 {
            insights.append("📈 Good progress! Your accuracy is \(Int(accuracy * 100))%")
        }
        
        if totalCards > 100 {
            insights.append("🎓 Impressive! You've reviewed over \(totalCards) cards")
        }
        
        let unsyncedSessions = recentSessions.filter { !$0.isSynced }
        if !unsyncedSessions.isEmpty {
            insights.append("📱 \(unsyncedSessions.count) sessions will sync when online")
        }
        
        if insights.isEmpty {
            insights.append("🚀 Start your learning journey today!")
        }
        
        return insights
    }
    
    private func countPendingSyncOperations(in context: ModelContext) async throws -> Int {
        var descriptor = FetchDescriptor<SyncOperation>(
            predicate: #Predicate<SyncOperation> { syncOp in
                syncOp.status == "pending"
            }
        )
        let operations = try context.fetch(descriptor)
        return operations.count
    }
    
    func refreshProgress() {
        calculateLocalProgress()
    }
    
    func getProgressForTimeframe(_ timeframe: ProgressTimeframe) -> LocalProgressData? {
        return localProgressData
    }
    
    // MARK: - Sync Integration
    
    func syncWithBackend() async {
        if NetworkMonitor.shared.isConnected {
            await OfflineSyncService.shared.syncPendingOperations()
            calculateLocalProgress()
        }
    }
}
