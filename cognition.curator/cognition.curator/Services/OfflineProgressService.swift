import Foundation
import CoreData
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

// MARK: - Offline Progress Service

@MainActor
class OfflineProgressService: ObservableObject {
    static let shared = OfflineProgressService()

    @Published var localProgressData: LocalProgressData?
    @Published var isCalculating = false

    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Auto-refresh when Core Data changes
        setupCoreDataNotifications()
        calculateLocalProgress()
    }

    private func setupCoreDataNotifications() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.calculateLocalProgress()
            }
            .store(in: &cancellables)
    }

    // MARK: - Local Progress Calculation

    func calculateLocalProgress() {
        guard !isCalculating else { return }

        isCalculating = true

        Task {
            let context = persistenceController.container.newBackgroundContext()

            await context.perform {
                do {
                    let progressData = try self.calculateProgressData(in: context)

                    Task { @MainActor in
                        self.localProgressData = progressData
                        self.isCalculating = false
                        print("📊 OfflineProgressService: Local progress calculated")
                    }
                } catch {
                    print("❌ OfflineProgressService: Failed to calculate progress: \(error)")
                    Task { @MainActor in
                        self.isCalculating = false
                    }
                }
            }
        }
    }

    private func calculateProgressData(in context: NSManagedObjectContext) throws -> LocalProgressData {
        // Calculate streak
        let streak = calculateCurrentStreak(in: context)
        let longestStreak = calculateLongestStreak(in: context)

        // Calculate total cards reviewed
        let totalCardsReviewed = try calculateTotalCardsReviewed(in: context)

        // Calculate total study time
        let totalStudyTime = try calculateTotalStudyTime(in: context)

        // Calculate overall accuracy
        let accuracy = try calculateOverallAccuracy(in: context)

        // Calculate cards due today
        let cardsDue = try calculateCardsDueToday(in: context)

        // Get recent sessions
        let recentSessions = try getRecentSessions(in: context)

        // Calculate weekly stats
        let weeklyStats = try calculateWeeklyStats(in: context)

        // Get top decks
        let topDecks = try getTopDecks(in: context)

        // Generate insights
        let insights = generateInsights(
            streak: streak,
            totalCards: totalCardsReviewed,
            accuracy: accuracy,
            recentSessions: recentSessions
        )

        // Count pending sync operations
        let pendingSyncCount = try countPendingSyncOperations(in: context)

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

    private func calculateCurrentStreak(in context: NSManagedObjectContext) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var currentStreak = 0
        var checkDate = today

        while true {
            let dayStart = checkDate
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

            let fetchRequest: NSFetchRequest<ReviewSession> = ReviewSession.fetchRequest()
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "reviewedAt >= %@", dayStart as NSDate),
                NSPredicate(format: "reviewedAt < %@", dayEnd as NSDate)
            ])
            fetchRequest.fetchLimit = 1

            do {
                let sessions = try context.fetch(fetchRequest)
                if sessions.isEmpty {
                    break
                } else {
                    currentStreak += 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                }
            } catch {
                print("❌ OfflineProgressService: Error calculating streak: \(error)")
                break
            }
        }

        return currentStreak
    }

    private func calculateLongestStreak(in context: NSManagedObjectContext) -> Int {
        // Simplified implementation - in production, you'd want to track this more efficiently
        return calculateCurrentStreak(in: context) // Placeholder
    }

    private func calculateTotalCardsReviewed(in context: NSManagedObjectContext) throws -> Int {
        let fetchRequest: NSFetchRequest<ReviewSession> = ReviewSession.fetchRequest()
        return try context.count(for: fetchRequest)
    }

    private func calculateTotalStudyTime(in context: NSManagedObjectContext) throws -> Int {
        // Calculate based on review sessions - estimate 30 seconds per review
        let totalReviews = try calculateTotalCardsReviewed(in: context)
        return (totalReviews * 30) / 60 // Convert to minutes
    }

    private func calculateOverallAccuracy(in context: NSManagedObjectContext) throws -> Double {
        let fetchRequest: NSFetchRequest<ReviewSession> = ReviewSession.fetchRequest()
        let sessions = try context.fetch(fetchRequest)

        guard !sessions.isEmpty else { return 0.0 }

        let correctSessions = sessions.filter { $0.difficulty >= 3 } // Good or Easy
        return Double(correctSessions.count) / Double(sessions.count)
    }

    private func calculateCardsDueToday(in context: NSManagedObjectContext) throws -> Int {
        let now = Date()
        let fetchRequest: NSFetchRequest<ReviewSession> = ReviewSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "nextReview <= %@", now as NSDate)

        // Get unique flashcards that are due
        let sessions = try context.fetch(fetchRequest)
        let uniqueFlashcards = Set(sessions.compactMap { $0.flashcard?.id })

        return uniqueFlashcards.count
    }

    private func getRecentSessions(in context: NSManagedObjectContext) throws -> [LocalSessionSummary] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let fetchRequest: NSFetchRequest<ReviewSession> = ReviewSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reviewedAt >= %@", sevenDaysAgo as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "reviewedAt", ascending: false)]
        fetchRequest.fetchLimit = 10

        let sessions = try context.fetch(fetchRequest)

        return sessions.compactMap { session in
            guard let id = session.id?.uuidString,
                  let reviewedAt = session.reviewedAt else { return nil }

            return LocalSessionSummary(
                id: id,
                date: reviewedAt,
                duration: 1, // Estimate 1 minute per session
                cardsReviewed: 1,
                accuracy: session.difficulty >= 3 ? 1.0 : 0.0,
                deckName: session.flashcard?.deck?.name,
                isSynced: session.syncStatus == "synced"
            )
        }
    }

    private func calculateWeeklyStats(in context: NSManagedObjectContext) throws -> [LocalDayStats] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyStats: [LocalDayStats] = []

        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

            let fetchRequest: NSFetchRequest<ReviewSession> = ReviewSession.fetchRequest()
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "reviewedAt >= %@", dayStart as NSDate),
                NSPredicate(format: "reviewedAt < %@", dayEnd as NSDate)
            ])

            let sessions = try context.fetch(fetchRequest)
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

    private func getTopDecks(in context: NSManagedObjectContext) throws -> [LocalDeckStats] {
        let fetchRequest: NSFetchRequest<Deck> = Deck.fetchRequest()
        let decks = try context.fetch(fetchRequest)

        return decks.compactMap { deck in
            guard let deckId = deck.id?.uuidString,
                  let deckName = deck.name else { return nil }

            let flashcards = deck.flashcards?.allObjects as? [Flashcard] ?? []
            let allSessions = flashcards.flatMap { $0.reviewSessions?.allObjects as? [ReviewSession] ?? [] }
            let correctSessions = allSessions.filter { $0.difficulty >= 3 }

            return LocalDeckStats(
                id: deckId,
                name: deckName,
                totalCards: flashcards.count,
                cardsReviewed: allSessions.count,
                accuracyRate: allSessions.isEmpty ? 0.0 : Double(correctSessions.count) / Double(allSessions.count),
                studyTimeMinutes: allSessions.count / 2, // Estimate
                lastReviewDate: allSessions.compactMap { $0.reviewedAt }.max()
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

    private func countPendingSyncOperations(in context: NSManagedObjectContext) throws -> Int {
        let fetchRequest: NSFetchRequest<SyncOperation> = SyncOperation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "status == %@", "pending")
        return try context.count(for: fetchRequest)
    }

    // MARK: - Public Interface

    func refreshProgress() {
        calculateLocalProgress()
    }

    func getProgressForTimeframe(_ timeframe: ProgressTimeframe) -> LocalProgressData? {
        // For now, return the same data regardless of timeframe
        // In production, you might want to calculate different periods
        return localProgressData
    }

    // MARK: - Sync Integration

    func syncWithBackend() async {
        // When online, this could sync local calculations with backend
        // and resolve any discrepancies
        if NetworkMonitor.shared.isConnected {
            await OfflineSyncService.shared.syncPendingOperations()
            // Recalculate after sync
            calculateLocalProgress()
        }
    }
}

// MARK: - Progress Timeframe

enum ProgressTimeframe: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        }
    }
}