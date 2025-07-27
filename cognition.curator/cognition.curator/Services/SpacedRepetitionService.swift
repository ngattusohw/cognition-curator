import Foundation
import CoreData

// MARK: - Review Mode Configuration
enum ReviewMode: String, CaseIterable {
    case normal = "normal"           // Only due cards
    case practice = "practice"       // Due + recent cards (last 3 days)
    case cram = "cram"               // All cards from selected decks

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .practice: return "Practice"
        case .cram: return "Cram"
        }
    }

    var description: String {
        switch self {
        case .normal: return "Review only cards that are due"
        case .practice: return "Practice recently reviewed cards"
        case .cram: return "Review all cards regardless of schedule"
        }
    }

    var isPremium: Bool {
        switch self {
        case .normal: return false
        case .practice: return true
        case .cram: return true
        }
    }
}

// MARK: - Card Learning State
enum CardState: String {
    case new = "new"               // Never reviewed
    case learning = "learning"     // In learning phase with short intervals
    case review = "review"         // Graduated to review phase
    case relearning = "relearning" // Failed review, back to learning
}

class SpacedRepetitionService {
    static let shared = SpacedRepetitionService()

    private init() {}

    // MARK: - Learning Phase Intervals (in minutes)
    private let learningSteps: [Double] = [1, 10] // 1 minute, then 10 minutes
    private let graduationInterval: Double = 1 // 1 day to graduate to review
    private let easyInterval: Double = 4 // 4 days for easy new cards

    // MARK: - Settings
    var currentReviewMode: ReviewMode {
        get {
            let rawValue = UserDefaults.standard.string(forKey: "reviewMode") ?? ReviewMode.normal.rawValue
            return ReviewMode(rawValue: rawValue) ?? .normal
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "reviewMode")
        }
    }

    var maxNewCardsPerDay: Int {
        get { UserDefaults.standard.integer(forKey: "maxNewCardsPerDay") == 0 ? 20 : UserDefaults.standard.integer(forKey: "maxNewCardsPerDay") }
        set { UserDefaults.standard.set(newValue, forKey: "maxNewCardsPerDay") }
    }

    var maxReviewCardsPerDay: Int {
        get { UserDefaults.standard.integer(forKey: "maxReviewCardsPerDay") == 0 ? 100 : UserDefaults.standard.integer(forKey: "maxReviewCardsPerDay") }
        set { UserDefaults.standard.set(newValue, forKey: "maxReviewCardsPerDay") }
    }

    // MARK: - Enhanced SM-2 Algorithm Implementation
    func calculateNextReview(for card: Flashcard, difficulty: Int16) -> Date {
        let reviewSessions = card.reviewSessions?.allObjects as? [ReviewSession] ?? []
        let sortedSessions = reviewSessions.sorted { $0.reviewedAt ?? Date() < $1.reviewedAt ?? Date() }

        let cardState = getCardState(card: card)
        let currentStep = getCurrentLearningStep(card: card)

        let newInterval: Double
        let newEaseFactor: Double

        // Get current ease factor from last session or default
        let currentEaseFactor = sortedSessions.last?.easeFactor ?? 2.5

        switch cardState {
        case .new, .learning, .relearning:
            newInterval = handleLearningPhase(difficulty: difficulty, currentStep: currentStep)
            newEaseFactor = currentEaseFactor // Don't change ease factor in learning

        case .review:
            (newInterval, newEaseFactor) = handleReviewPhase(
                difficulty: difficulty,
                currentInterval: sortedSessions.last?.interval ?? 1.0,
                currentEaseFactor: currentEaseFactor
            )
        }

        // Create new review session
        let context = card.managedObjectContext!
        let newSession = ReviewSession(context: context)
        newSession.id = UUID()
        newSession.flashcard = card
        newSession.difficulty = difficulty
        newSession.interval = newInterval
        newSession.easeFactor = newEaseFactor
        newSession.reviewedAt = Date()

        // Calculate next review date
        if newInterval < 1440 { // Less than 24 hours (in minutes)
            newSession.nextReview = Calendar.current.date(byAdding: .minute, value: Int(newInterval), to: Date())
        } else { // Days
            newSession.nextReview = Calendar.current.date(byAdding: .day, value: Int(newInterval / 1440), to: Date())
        }

        return newSession.nextReview ?? Date()
    }

    private func handleLearningPhase(difficulty: Int16, currentStep: Int) -> Double {
        switch difficulty {
        case 0: // Again - restart learning
            return learningSteps[0]
        case 1: // Hard - repeat current step
            return learningSteps[min(currentStep, learningSteps.count - 1)]
        case 2: // Good - advance to next step or graduate
            if currentStep + 1 < learningSteps.count {
                return learningSteps[currentStep + 1]
            } else {
                return graduationInterval * 1440 // Convert to minutes
            }
        case 3: // Easy - skip to easy interval
            return easyInterval * 1440 // Convert to minutes
        default:
            return learningSteps[0]
        }
    }

    private func handleReviewPhase(difficulty: Int16, currentInterval: Double, currentEaseFactor: Double) -> (interval: Double, easeFactor: Double) {
        let newEaseFactor: Double
        let newInterval: Double

        switch difficulty {
        case 0: // Again - back to learning
            newEaseFactor = max(1.3, currentEaseFactor - 0.2)
            newInterval = learningSteps[0]
        case 1: // Hard
            newEaseFactor = max(1.3, currentEaseFactor - 0.15)
            newInterval = max(1, currentInterval * 1.2) * 1440
        case 2: // Good
            newEaseFactor = currentEaseFactor
            newInterval = max(1, currentInterval / 1440 * currentEaseFactor) * 1440
        case 3: // Easy
            newEaseFactor = currentEaseFactor + 0.15
            newInterval = max(1, currentInterval / 1440 * currentEaseFactor * 1.3) * 1440
        default:
            newEaseFactor = currentEaseFactor
            newInterval = currentInterval
        }

        return (newInterval, newEaseFactor)
    }

    private func getCardState(card: Flashcard) -> CardState {
        let reviewSessions = card.reviewSessions?.allObjects as? [ReviewSession] ?? []

        guard !reviewSessions.isEmpty else { return .new }

        let sortedSessions = reviewSessions.sorted { $0.reviewedAt ?? Date() < $1.reviewedAt ?? Date() }
        let lastSession = sortedSessions.last!

        // Check if last answer was "Again" in review phase
        if lastSession.difficulty == 0 && lastSession.interval >= 1440 {
            return .relearning
        }

        // Check if still in learning phase
        if lastSession.interval < 1440 {
            return .learning
        }

        return .review
    }

    private func getCurrentLearningStep(card: Flashcard) -> Int {
        let reviewSessions = card.reviewSessions?.allObjects as? [ReviewSession] ?? []
        let learningSessions = reviewSessions.filter { $0.interval < 1440 }
        return learningSessions.count
    }

    // MARK: - Get Cards for Review (Enhanced)
    func getCardsForTodaySession(context: NSManagedObjectContext, limit: Int? = nil, force: Bool = false, mode: ReviewMode? = nil) -> [Flashcard] {
        let reviewMode = mode ?? currentReviewMode
        let actualLimit = limit ?? (reviewMode == .cram ? 50 : 20)

        if force && reviewMode == .normal {
            // Force mode with normal settings - get recent cards
            return getRecentCards(context: context, limit: actualLimit)
        }

        switch reviewMode {
        case .normal:
            return getNormalReviewCards(context: context, limit: actualLimit)
        case .practice:
            return getPracticeCards(context: context, limit: actualLimit)
        case .cram:
            return getCramCards(context: context, limit: actualLimit)
        }
    }

    private func getNormalReviewCards(context: NSManagedObjectContext, limit: Int) -> [Flashcard] {
        let now = Date()

        // First get new cards (prioritize these)
        let newRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        newRequest.predicate = NSPredicate(format: "reviewSessions.@count == 0")
        newRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Flashcard.createdAt, ascending: true)]
        newRequest.fetchLimit = min(limit, maxNewCardsPerDay)

        // Then get due cards
        let dueRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        dueRequest.predicate = NSPredicate(format: "ANY reviewSessions.nextReview <= %@", now as NSDate)
        dueRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Flashcard.createdAt, ascending: true)]
        dueRequest.fetchLimit = limit

        do {
            let newCards = try context.fetch(newRequest)
            let dueCards = try context.fetch(dueRequest)

            // Shuffle each group separately to maintain algorithm priority
            let shuffledNewCards = newCards.shuffled()
            let shuffledDueCards = dueCards.shuffled()

            // Combine without duplicates and respect the limit
            // New cards first (algorithm priority), then due cards
            var combinedCards: [Flashcard] = []
            combinedCards.append(contentsOf: shuffledNewCards)

            for dueCard in shuffledDueCards {
                if !combinedCards.contains(where: { $0.id == dueCard.id }) && combinedCards.count < limit {
                    combinedCards.append(dueCard)
                }
            }

            print("📚 Found \(newCards.count) new cards, \(dueCards.count) due cards, returning \(combinedCards.count) total (shuffled within groups)")
            return combinedCards
        } catch {
            print("Error fetching normal review cards: \(error)")
            return []
        }
    }

    private func getPracticeCards(context: NSManagedObjectContext, limit: Int) -> [Flashcard] {
        let now = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()

        // Get due cards + cards reviewed in last 3 days
        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "reviewSessions.@count == 0"), // New cards
            NSPredicate(format: "ANY reviewSessions.nextReview <= %@", now as NSDate), // Due cards
            NSPredicate(format: "ANY reviewSessions.reviewedAt >= %@", threeDaysAgo as NSDate) // Recent cards
        ])

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Flashcard.createdAt, ascending: true)
        ]
        request.fetchLimit = limit

        do {
            let cards = try context.fetch(request)
            // Shuffle practice cards for variety in practice sessions
            let shuffledCards = cards.shuffled()
            print("📚 Found \(cards.count) practice cards (shuffled)")
            return shuffledCards
        } catch {
            print("Error fetching practice cards: \(error)")
            return []
        }
    }

    private func getCramCards(context: NSManagedObjectContext, limit: Int) -> [Flashcard] {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Flashcard.createdAt, ascending: false) // Newest first for cram
        ]
        request.fetchLimit = limit

        do {
            let cards = try context.fetch(request)
            // Shuffle cram cards for varied practice
            let shuffledCards = cards.shuffled()
            print("📚 Found \(cards.count) cram cards (shuffled)")
            return shuffledCards
        } catch {
            print("Error fetching cram cards: \(error)")
            return []
        }
    }

    private func getRecentCards(context: NSManagedObjectContext, limit: Int) -> [Flashcard] {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        request.fetchLimit = limit
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Flashcard.createdAt, ascending: false)]

        do {
            let cards = try context.fetch(request)
            // Shuffle recent cards to avoid repetitive patterns
            let shuffledCards = cards.shuffled()
            print("📚 Found \(cards.count) recent cards (shuffled)")
            return shuffledCards
        } catch {
            print("Error fetching recent cards: \(error)")
            return []
        }
    }

    // MARK: - Deck-Specific Review Methods
    func getCardsFromDecks(context: NSManagedObjectContext, deckIds: [UUID], mode: ReviewMode = .normal, limit: Int = 50) -> [Flashcard] {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()

        // Filter by selected decks
        request.predicate = NSPredicate(format: "deck.id IN %@", deckIds)

        // Apply mode-specific filtering
        switch mode {
        case .normal:
            // Only due and new cards
            let now = Date()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "deck.id IN %@", deckIds),
                NSCompoundPredicate(orPredicateWithSubpredicates: [
                    NSPredicate(format: "reviewSessions.@count == 0"), // New cards
                    NSPredicate(format: "ANY reviewSessions.nextReview <= %@", now as NSDate) // Due cards
                ])
            ])
        case .practice:
            // Due + recent cards (last 3 days)
            let now = Date()
            let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "deck.id IN %@", deckIds),
                NSCompoundPredicate(orPredicateWithSubpredicates: [
                    NSPredicate(format: "reviewSessions.@count == 0"), // New cards
                    NSPredicate(format: "ANY reviewSessions.nextReview <= %@", now as NSDate), // Due cards
                    NSPredicate(format: "ANY reviewSessions.reviewedAt >= %@", threeDaysAgo as NSDate) // Recent cards
                ])
            ])
        case .cram:
            // All cards from selected decks (already filtered above)
            break
        }

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Flashcard.createdAt, ascending: mode == .cram ? false : true)
        ]
        request.fetchLimit = limit

        do {
            let cards = try context.fetch(request)
            // Shuffle deck cards for variety in deck review
            let shuffledCards = cards.shuffled()
            print("📚 Deck review: Found \(cards.count) cards from \(deckIds.count) decks (\(mode.displayName) mode) (shuffled)")
            return shuffledCards
        } catch {
            print("Error fetching cards from decks: \(error)")
            return []
        }
    }

    func getDeckReviewStats(context: NSManagedObjectContext, deckIds: [UUID]) -> (total: Int, new: Int, due: Int, learning: Int) {
        let now = Date()

        // Total cards in selected decks
        let totalRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        totalRequest.predicate = NSPredicate(format: "deck.id IN %@", deckIds)
        let totalCount = (try? context.count(for: totalRequest)) ?? 0

        // New cards
        let newRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        newRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "deck.id IN %@", deckIds),
            NSPredicate(format: "reviewSessions.@count == 0")
        ])
        let newCount = (try? context.count(for: newRequest)) ?? 0

        // Due cards
        let dueRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        dueRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "deck.id IN %@", deckIds),
            NSPredicate(format: "ANY reviewSessions.nextReview <= %@", now as NSDate)
        ])
        let dueCount = (try? context.count(for: dueRequest)) ?? 0

        // Learning cards
        let learningRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        learningRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "deck.id IN %@", deckIds),
            NSPredicate(format: "ANY reviewSessions.interval < 1440 AND ANY reviewSessions.nextReview <= %@", now as NSDate)
        ])
        let learningCount = (try? context.count(for: learningRequest)) ?? 0

        return (totalCount, newCount, dueCount, learningCount)
    }

    // MARK: - Legacy Support
    func getCardsDueForReview(context: NSManagedObjectContext) -> [Flashcard] {
        return getNormalReviewCards(context: context, limit: maxReviewCardsPerDay)
    }

    // MARK: - Calculate Review Statistics
    func calculateReviewStats(for card: Flashcard) -> ReviewStats {
        let reviewSessions = card.reviewSessions?.allObjects as? [ReviewSession] ?? []
        let totalReviews = reviewSessions.count
        let correctReviews = reviewSessions.filter { $0.difficulty >= 2 }.count
        let accuracy = totalReviews > 0 ? Double(correctReviews) / Double(totalReviews) : 0.0

        let cardState = getCardState(card: card)
        let nextReview = reviewSessions.sorted { $0.reviewedAt ?? Date() < $1.reviewedAt ?? Date() }.last?.nextReview

        return ReviewStats(
            totalReviews: totalReviews,
            correctReviews: correctReviews,
            accuracy: accuracy,
            lastReviewed: reviewSessions.last?.reviewedAt,
            nextReview: nextReview,
            cardState: cardState,
            easeFactor: reviewSessions.last?.easeFactor ?? 2.5
        )
    }

    // MARK: - Review Statistics for Home Screen
    func getTodayReviewStats(context: NSManagedObjectContext) -> (dueCards: Int, newCards: Int, learningCards: Int) {
        let now = Date()

        // Due cards
        let dueRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        dueRequest.predicate = NSPredicate(format: "ANY reviewSessions.nextReview <= %@", now as NSDate)
        let dueCount = (try? context.count(for: dueRequest)) ?? 0

        // New cards
        let newRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        newRequest.predicate = NSPredicate(format: "reviewSessions.@count == 0")
        let newCount = (try? context.count(for: newRequest)) ?? 0

        // Learning cards (interval < 1 day)
        let learningRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        learningRequest.predicate = NSPredicate(format: "ANY reviewSessions.interval < 1440 AND ANY reviewSessions.nextReview <= %@", now as NSDate)
        let learningCount = (try? context.count(for: learningRequest)) ?? 0

        return (dueCount, newCount, learningCount)
    }
}

// MARK: - Review Statistics
struct ReviewStats {
    let totalReviews: Int
    let correctReviews: Int
    let accuracy: Double
    let lastReviewed: Date?
    let nextReview: Date?
    let cardState: CardState
    let easeFactor: Double
}

// MARK: - Difficulty Levels
enum DifficultyLevel: Int16, CaseIterable {
    case again = 0
    case hard = 1
    case good = 2
    case easy = 3

    var displayName: String {
        switch self {
        case .again: return "Again"
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }

    var color: String {
        switch self {
        case .again: return "red"
        case .hard: return "orange"
        case .good: return "green"
        case .easy: return "blue"
        }
    }

    var description: String {
        switch self {
        case .again: return "Incorrect - review again soon"
        case .hard: return "Difficult - extend interval slightly"
        case .good: return "Correct - normal interval"
        case .easy: return "Easy - longer interval"
        }
    }
}
