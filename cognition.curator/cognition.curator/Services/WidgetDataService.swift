//
//  WidgetDataService.swift
//  cognition.curator
//
//  Created by Assistant on 7/27/25.
//

import Foundation
import SwiftData
import WidgetKit

// MARK: - Widget Card Data
struct WidgetCardData {
    let question: String
    let answer: String
    let deckName: String
    let cardId: UUID
}

class WidgetDataService {
    static let shared = WidgetDataService()

    private let sharedDefaults: UserDefaults
    private let persistenceController = PersistenceController.shared
    private let appGroupId = "group.collect.software.cognition-curator"
    private var isAppGroupAvailable: Bool = false

    private init() {
        // Use App Groups to share data with widget
        if let defaults = UserDefaults(suiteName: appGroupId) {
            self.sharedDefaults = defaults
            self.isAppGroupAvailable = true
            print("✅ WidgetDataService: App Group '\(appGroupId)' available")
        } else {
            self.sharedDefaults = UserDefaults.standard
            self.isAppGroupAvailable = false
            print("❌ WidgetDataService: App Group NOT available, using standard defaults")
        }
    }

    /// Update widget with current due card counts and top review card
    func updateWidgetData() {
        print("🎯 WidgetDataService: updateWidgetData() called")
        print("🎯 WidgetDataService: App Group available: \(isAppGroupAvailable)")

        Task { @MainActor in
            let counts = getDueCardCounts()
            let topCard = getTopReviewCard()

            // Debug logging
            print("🎯 WidgetDataService: Fetched data - Due: \(counts.dueCount), HasCards: \(counts.hasCards)")
            if let card = topCard {
                print("🎯 WidgetDataService: Top card - '\(card.question)' from '\(card.deckName)'")
            } else {
                print("🎯 WidgetDataService: No top card found in database")
            }

            // Update shared UserDefaults with counts
            self.sharedDefaults.set(counts.dueCount, forKey: "widget.dueCardsCount")
            self.sharedDefaults.set(counts.hasCards, forKey: "widget.hasCards")
            self.sharedDefaults.set(Date(), forKey: "widget.lastUpdated")

            // Update shared UserDefaults with top card data
            // Use atomic updates to ensure data consistency
            if let card = topCard {
                // Validate card data before writing
                if card.question.isEmpty || card.answer.isEmpty || card.deckName.isEmpty {
                    print("⚠️ WidgetDataService: Top card has empty fields, clearing top card data")
                    self.sharedDefaults.removeObject(forKey: "widget.topCard.question")
                    self.sharedDefaults.removeObject(forKey: "widget.topCard.answer")
                    self.sharedDefaults.removeObject(forKey: "widget.topCard.deckName")
                    self.sharedDefaults.removeObject(forKey: "widget.topCard.cardId")
                    self.sharedDefaults.set(false, forKey: "widget.topCard.hasContent")
                } else {
                    self.sharedDefaults.set(card.question, forKey: "widget.topCard.question")
                    self.sharedDefaults.set(card.answer, forKey: "widget.topCard.answer")
                    self.sharedDefaults.set(card.deckName, forKey: "widget.topCard.deckName")
                    self.sharedDefaults.set(card.cardId.uuidString, forKey: "widget.topCard.cardId")
                    self.sharedDefaults.set(true, forKey: "widget.topCard.hasContent")
                }
            } else {
                // Clear top card data when no cards available
                self.sharedDefaults.removeObject(forKey: "widget.topCard.question")
                self.sharedDefaults.removeObject(forKey: "widget.topCard.answer")
                self.sharedDefaults.removeObject(forKey: "widget.topCard.deckName")
                self.sharedDefaults.removeObject(forKey: "widget.topCard.cardId")
                self.sharedDefaults.set(false, forKey: "widget.topCard.hasContent")
            }

            // Force synchronization - ensure data is persisted before reloading widget
            self.sharedDefaults.synchronize()

            // Log the exact data we're sharing for debugging
            print("🎯 WidgetDataService: Shared data verification:")
            print("  - widget.dueCardsCount: \(self.sharedDefaults.integer(forKey: "widget.dueCardsCount"))")
            print("  - widget.topCard.hasContent: \(self.sharedDefaults.bool(forKey: "widget.topCard.hasContent"))")
            print("  - widget.topCard.question: \(self.sharedDefaults.string(forKey: "widget.topCard.question") ?? "nil")")
        }
        
        // Reload widgets after data is written (outside the Task to ensure it happens after completion)
        Task { @MainActor in
            // Small delay to ensure UserDefaults synchronization completes
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Force widget reload with multiple strategies
            WidgetCenter.shared.reloadAllTimelines()
            
            // Also try reloading specific widget kind
            WidgetCenter.shared.reloadTimelines(ofKind: "CognitionCuratorWidget")
            
            print("🎯 WidgetDataService: Widget timeline reloaded (all + specific)")
        }
    }

    @MainActor
    private func getDueCardCounts() -> (dueCount: Int, hasCards: Bool) {
        let context = persistenceController.container.mainContext
        let now = Date()

        do {
            let descriptor = FetchDescriptor<Flashcard>()
            let allCards = try context.fetch(descriptor)

            guard !allCards.isEmpty else {
                return (dueCount: 0, hasCards: false)
            }

            // Filter out silenced decks
            let activeCards = allCards.filter { card in
                !isDeckSilenced(card.deck)
            }

            guard !activeCards.isEmpty else {
                return (dueCount: 0, hasCards: true) // Has cards but all silenced
            }

            let dueCards = activeCards.filter { card in
                guard let sessions = card.reviewSessions, !sessions.isEmpty else {
                    return true // New cards are considered due
                }
                return sessions.contains { ($0.nextReview ?? Date()) <= now }
            }

            let uniqueDueCards = Set(dueCards.map { $0.id }).count
            return (dueCount: uniqueDueCards, hasCards: true)
        } catch {
            print("❌ WidgetDataService: Error fetching due cards: \(error)")
            return (dueCount: 0, hasCards: false)
        }
    }

    @MainActor
    private func getTopReviewCard() -> WidgetCardData? {
        let context = persistenceController.container.mainContext
        let now = Date()

        do {
            let descriptor = FetchDescriptor<Flashcard>()
            let allCards = try context.fetch(descriptor)

            // Filter out silenced decks
            let activeCards = allCards.filter { card in
                !isDeckSilenced(card.deck)
            }

            guard !activeCards.isEmpty else {
                print("🎯 WidgetDataService: No active cards (all decks may be silenced)")
                return nil
            }

            // Prioritize: new cards first, then due cards sorted by nextReview date
            let newCards = activeCards.filter { card in
                card.reviewSessions?.isEmpty ?? true
            }

            // Sort new cards by creation date (oldest first) for consistent selection
            let sortedNewCards = newCards.sorted { card1, card2 in
                return card1.createdAt < card2.createdAt
            }

            let dueCards = activeCards.filter { card in
                guard let sessions = card.reviewSessions, !sessions.isEmpty else {
                    return false // Already handled as new cards
                }
                return sessions.contains { ($0.nextReview ?? Date()) <= now }
            }

            // Sort due cards by nextReview date (earliest first)
            // Cards with nil nextReview are treated as most urgent (Date.distantPast)
            let sortedDueCards = dueCards.sorted { card1, card2 in
                let sessions1 = card1.reviewSessions ?? []
                let sessions2 = card2.reviewSessions ?? []
                
                // Get the earliest nextReview for each card
                let nextReviews1 = sessions1.compactMap { $0.nextReview }
                let nextReviews2 = sessions2.compactMap { $0.nextReview }
                
                // If a card has no valid nextReview dates, it's most urgent (nil = due now)
                if nextReviews1.isEmpty && nextReviews2.isEmpty {
                    return false // Equal priority, maintain order
                } else if nextReviews1.isEmpty {
                    return true // Card1 has nil nextReview, prioritize it
                } else if nextReviews2.isEmpty {
                    return false // Card2 has nil nextReview, prioritize it
                }
                
                // Both cards have valid nextReview dates, sort by earliest
                let nextReview1 = nextReviews1.min() ?? Date.distantFuture
                let nextReview2 = nextReviews2.min() ?? Date.distantFuture
                return nextReview1 < nextReview2
            }

            // Get the top card: oldest new card first, then earliest due card
            let topCard = sortedNewCards.first ?? sortedDueCards.first

            guard let card = topCard else {
                print("🎯 WidgetDataService: No due or new cards found")
                return nil
            }

            // Get deck name - handle empty strings too
            var deckName = card.deck?.name ?? ""
            if deckName.isEmpty {
                deckName = "Flashcards"
            }

            print("🎯 WidgetDataService: Selected top card - '\(card.question)' from '\(deckName)' (new: \(newCards.count), due: \(dueCards.count))")

            return WidgetCardData(
                question: card.question,
                answer: card.answer,
                deckName: deckName,
                cardId: card.id
            )
        } catch {
            print("❌ WidgetDataService: Error fetching top card: \(error)")
            return nil
        }
    }

    /// Check if a deck is silenced (matches SpacedRepetitionService logic)
    private func isDeckSilenced(_ deck: Deck?) -> Bool {
        guard let deck = deck else { return false }
        guard deck.isSilenced else { return false }
        
        if deck.silenceType == "permanent" {
            return true
        }
        
        if deck.silenceType == "temporary",
           let endDate = deck.silenceEndDate {
            return Date() < endDate
        }
        
        return false
    }

    /// Call this when app becomes active to refresh widget data
    func refreshOnAppLaunch() {
        print("🎯 WidgetDataService: App launched - refreshing widget data")
        updateWidgetData()
    }

    /// Call this after completing reviews to update counts
    func refreshAfterReview() {
        print("🎯 WidgetDataService: Review completed - refreshing widget data")
        updateWidgetData()
    }

    /// Call this when new cards are added
    func refreshAfterAddingCards() {
        print("🎯 WidgetDataService: Cards added - refreshing widget data")
        updateWidgetData()
    }

    /// Debug method to check current shared UserDefaults values
    func debugSharedDefaults() {
        let dueCount = sharedDefaults.integer(forKey: "widget.dueCardsCount")
        let hasCards = sharedDefaults.bool(forKey: "widget.hasCards")
        let lastUpdated = sharedDefaults.object(forKey: "widget.lastUpdated") as? Date

        let hasTopCard = sharedDefaults.bool(forKey: "widget.topCard.hasContent")
        let topCardQuestion = sharedDefaults.string(forKey: "widget.topCard.question")
        let topCardAnswer = sharedDefaults.string(forKey: "widget.topCard.answer")
        let topCardDeckName = sharedDefaults.string(forKey: "widget.topCard.deckName")
        let topCardId = sharedDefaults.string(forKey: "widget.topCard.cardId")

        print("🎯 WidgetDataService Debug (Main App):")
        print("  - App Group Available: \(isAppGroupAvailable)")
        print("  - App Group ID: \(appGroupId)")
        print("  - Due Count: \(dueCount)")
        print("  - Has Cards: \(hasCards)")
        print("  - Last Updated: \(lastUpdated?.description ?? "Never")")
        print("  - Has Top Card: \(hasTopCard)")
        if hasTopCard {
            print("  - Top Card Question: \(topCardQuestion ?? "N/A")")
            print("  - Top Card Answer: \(topCardAnswer ?? "N/A")")
            print("  - Top Card Deck: \(topCardDeckName ?? "N/A")")
            print("  - Top Card ID: \(topCardId ?? "N/A")")
        }

        // Also check SwiftData for cards
        Task { @MainActor in
            let counts = getDueCardCounts()
            let topCard = getTopReviewCard()
            print("  - SwiftData Total Cards: \(counts.hasCards ? "Yes" : "No")")
            print("  - SwiftData Due Cards: \(counts.dueCount)")
            if let card = topCard {
                print("  - SwiftData Top Card: '\(card.question)' from '\(card.deckName)'")
            } else {
                print("  - SwiftData Top Card: None found")
            }
        }
    }

    /// Verify that data can be read back from shared UserDefaults (for debugging)
    func verifyDataSharing() -> Bool {
        // Write a test value and read it back
        let testKey = "widget.test.sharing"
        let testValue = UUID().uuidString
        sharedDefaults.set(testValue, forKey: testKey)
        sharedDefaults.synchronize()
        
        // Try to read it back
        if let readValue = sharedDefaults.string(forKey: testKey), readValue == testValue {
            sharedDefaults.removeObject(forKey: testKey)
            print("✅ WidgetDataService: Data sharing verification successful")
            return true
        } else {
            print("❌ WidgetDataService: Data sharing verification FAILED")
            return false
        }
    }
}
