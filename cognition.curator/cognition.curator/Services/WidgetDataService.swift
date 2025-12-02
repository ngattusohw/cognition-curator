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
            if let card = topCard {
                self.sharedDefaults.set(card.question, forKey: "widget.topCard.question")
                self.sharedDefaults.set(card.answer, forKey: "widget.topCard.answer")
                self.sharedDefaults.set(card.deckName, forKey: "widget.topCard.deckName")
                self.sharedDefaults.set(card.cardId.uuidString, forKey: "widget.topCard.cardId")
                self.sharedDefaults.set(true, forKey: "widget.topCard.hasContent")
            } else {
                // Clear top card data when no cards available
                self.sharedDefaults.removeObject(forKey: "widget.topCard.question")
                self.sharedDefaults.removeObject(forKey: "widget.topCard.answer")
                self.sharedDefaults.removeObject(forKey: "widget.topCard.deckName")
                self.sharedDefaults.removeObject(forKey: "widget.topCard.cardId")
                self.sharedDefaults.set(false, forKey: "widget.topCard.hasContent")
            }

            // Force synchronization
            self.sharedDefaults.synchronize()

            // Force widget reload with multiple strategies
            WidgetCenter.shared.reloadAllTimelines()

            // Also try reloading specific widget kind
            WidgetCenter.shared.reloadTimelines(ofKind: "CognitionCuratorWidget")

            print("🎯 WidgetDataService: Widget timeline reloaded (all + specific)")

            // Log the exact data we're sharing for debugging
            print("🎯 WidgetDataService: Shared data verification:")
            print("  - widget.dueCardsCount: \(self.sharedDefaults.integer(forKey: "widget.dueCardsCount"))")
            print("  - widget.topCard.hasContent: \(self.sharedDefaults.bool(forKey: "widget.topCard.hasContent"))")
            print("  - widget.topCard.question: \(self.sharedDefaults.string(forKey: "widget.topCard.question") ?? "nil")")
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

            let dueCards = allCards.filter { card in
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
            let descriptor = FetchDescriptor<Flashcard>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            let allCards = try context.fetch(descriptor)

            // Find the first due card (new or review)
            let dueCard = allCards.first { card in
                guard let sessions = card.reviewSessions, !sessions.isEmpty else {
                    return true // New cards are prioritized
                }
                return sessions.contains { ($0.nextReview ?? Date()) <= now }
            }

            guard let card = dueCard else {
                return nil
            }

            // Get deck name - handle empty strings too
            var deckName = card.deck?.name ?? ""
            if deckName.isEmpty {
                deckName = "Flashcards"
            }

            print("🎯 WidgetDataService: Card deck relationship - deck exists: \(card.deck != nil), name: '\(card.deck?.name ?? "nil")'")

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
        let topCardDeckName = sharedDefaults.string(forKey: "widget.topCard.deckName")

        print("🎯 WidgetDataService Debug (Main App):")
        print("  - App Group Available: \(isAppGroupAvailable)")
        print("  - App Group ID: \(appGroupId)")
        print("  - Due Count: \(dueCount)")
        print("  - Has Cards: \(hasCards)")
        print("  - Last Updated: \(lastUpdated?.description ?? "Never")")
        print("  - Has Top Card: \(hasTopCard)")
        if hasTopCard {
            print("  - Top Card Question: \(topCardQuestion ?? "N/A")")
            print("  - Top Card Deck: \(topCardDeckName ?? "N/A")")
        }

        // Also check SwiftData for cards
        Task { @MainActor in
            let counts = getDueCardCounts()
            print("  - SwiftData Total Cards: \(counts.hasCards ? "Yes" : "No")")
            print("  - SwiftData Due Cards: \(counts.dueCount)")
        }
    }
}
