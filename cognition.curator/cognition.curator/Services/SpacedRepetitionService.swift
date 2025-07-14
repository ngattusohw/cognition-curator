import Foundation
import CoreData

class SpacedRepetitionService {
    static let shared = SpacedRepetitionService()
    
    private init() {}
    
    // MARK: - SM-2 Algorithm Implementation
    func calculateNextReview(for card: Flashcard, difficulty: Int16) -> Date {
        let reviewSessions = card.reviewSessions?.allObjects as? [ReviewSession] ?? []
        let sortedSessions = reviewSessions.sorted { $0.reviewedAt ?? Date() < $1.reviewedAt ?? Date() }
        
        let currentInterval: Double
        let currentEaseFactor: Double
        
        if let lastSession = sortedSessions.last {
            currentInterval = lastSession.interval
            // For simplicity, we'll use a fixed ease factor of 2.5
            currentEaseFactor = 2.5
        } else {
            // First review
            currentInterval = 1.0
            currentEaseFactor = 2.5
        }
        
        let newInterval: Double
        let newEaseFactor: Double
        
        switch difficulty {
        case 0: // Again
            newInterval = 1.0
            newEaseFactor = max(1.3, currentEaseFactor - 0.2)
        case 1: // Hard
            newInterval = currentInterval * 1.2
            newEaseFactor = max(1.3, currentEaseFactor - 0.15)
        case 2: // Good
            newInterval = currentInterval * currentEaseFactor
            newEaseFactor = currentEaseFactor
        case 3: // Easy
            newInterval = currentInterval * currentEaseFactor * 1.3
            newEaseFactor = currentEaseFactor + 0.15
        default:
            newInterval = currentInterval
            newEaseFactor = currentEaseFactor
        }
        
        // Create new review session
        let context = card.managedObjectContext
        let newSession = ReviewSession(context: context!)
        newSession.id = UUID()
        newSession.flashcard = card
        newSession.difficulty = difficulty
        newSession.interval = newInterval
        newSession.reviewedAt = Date()
        newSession.nextReview = Calendar.current.date(byAdding: .day, value: Int(newInterval), to: Date())
        
        return newSession.nextReview ?? Date()
    }
    
    // MARK: - Get Cards Due for Review
    func getCardsDueForReview(context: NSManagedObjectContext) -> [Flashcard] {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        
        // Get cards that are due for review (nextReview <= now) or have never been reviewed
        let now = Date()
        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "reviewSessions.@count == 0"),
            NSPredicate(format: "ANY reviewSessions.nextReview <= %@", now as NSDate)
        ])
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching cards due for review: \(error)")
            return []
        }
    }
    
    // MARK: - Get Cards for Today's Review Session
    func getCardsForTodaySession(context: NSManagedObjectContext, limit: Int = 20, force: Bool = false) -> [Flashcard] {
        if force {
            // When forcing, get all cards regardless of due date
            let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
            request.fetchLimit = limit
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Flashcard.createdAt, ascending: false)]
            
            do {
                return try context.fetch(request)
            } catch {
                print("Error fetching cards for forced review: \(error)")
                return []
            }
        } else {
            // Normal behavior - only get cards that are due
            let dueCards = getCardsDueForReview(context: context)
            return Array(dueCards.prefix(limit))
        }
    }
    
    // MARK: - Calculate Review Statistics
    func calculateReviewStats(for card: Flashcard) -> ReviewStats {
        let reviewSessions = card.reviewSessions?.allObjects as? [ReviewSession] ?? []
        let totalReviews = reviewSessions.count
        let correctReviews = reviewSessions.filter { $0.difficulty >= 2 }.count
        let accuracy = totalReviews > 0 ? Double(correctReviews) / Double(totalReviews) : 0.0
        
        return ReviewStats(
            totalReviews: totalReviews,
            correctReviews: correctReviews,
            accuracy: accuracy,
            lastReviewed: reviewSessions.last?.reviewedAt,
            nextReview: reviewSessions.last?.nextReview
        )
    }
}

// MARK: - Review Statistics
struct ReviewStats {
    let totalReviews: Int
    let correctReviews: Int
    let accuracy: Double
    let lastReviewed: Date?
    let nextReview: Date?
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
} 