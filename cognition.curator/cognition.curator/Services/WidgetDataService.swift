//
//  WidgetDataService.swift
//  cognition.curator
//
//  Created by Assistant on 7/27/25.
//

import Foundation
import CoreData
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

    private init() {
        // Use App Groups to share data with widget
        self.sharedDefaults = UserDefaults(suiteName: "group.collect.software.cognition-curator")
                             ?? UserDefaults.standard
    }

    /// Update widget with current due card counts and top review card
    func updateWidgetData() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }

            let counts = self.getDueCardCounts()
            let topCard = self.getTopReviewCard()

            // Debug logging
            print("🎯 WidgetDataService: Updating widget data - Due: \(counts.dueCount), HasCards: \(counts.hasCards)")
            if let card = topCard {
                print("🎯 WidgetDataService: Top card - \(card.question) from deck \(card.deckName)")
            } else {
                print("🎯 WidgetDataService: No top card available")
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

            DispatchQueue.main.async {
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
    }

    private func getDueCardCounts() -> (dueCount: Int, hasCards: Bool) {
        let context = PersistenceController.shared.container.viewContext
        let now = Date()

        var totalDue = 0
        var hasAnyCards = false

        context.performAndWait {
            // Count total cards to check if user has any cards at all
            let allCardsRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
            let totalCards = (try? context.count(for: allCardsRequest)) ?? 0
            hasAnyCards = totalCards > 0

            if hasAnyCards {
                // Count NEW cards (no review sessions)
                let newRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
                newRequest.predicate = NSPredicate(format: "reviewSessions.@count == 0")
                let newCount = (try? context.count(for: newRequest)) ?? 0

                // Count DUE cards (have review sessions but next review is due)
                let dueRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
                dueRequest.predicate = NSPredicate(format: "reviewSessions.@count > 0 AND ANY reviewSessions.nextReview <= %@", now as NSDate)
                let dueCount = (try? context.count(for: dueRequest)) ?? 0

                totalDue = newCount + dueCount

                // Debug logging
                print("🎯 WidgetDataService: Total cards: \(totalCards), New: \(newCount), Due: \(dueCount), Total Due: \(totalDue)")
            }
        }

        return (dueCount: totalDue, hasCards: hasAnyCards)
    }

    private func getTopReviewCard() -> WidgetCardData? {
        let context = PersistenceController.shared.container.viewContext
        let now = Date()

        var topCard: WidgetCardData? = nil

        context.performAndWait {
            // First priority: Get new cards (same logic as SpacedRepetitionService)
            let newRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
            let newCardPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "reviewSessions.@count == 0"),
                silencedDeckFilterPredicate()
            ])
            newRequest.predicate = newCardPredicate
            newRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Flashcard.createdAt, ascending: true)]
            newRequest.fetchLimit = 1

            do {
                let newCards = try context.fetch(newRequest)
                if let card = newCards.first,
                   let question = card.question,
                   let answer = card.answer,
                   let deckName = card.deck?.name,
                   let cardId = card.id {
                    topCard = WidgetCardData(
                        question: question,
                        answer: answer,
                        deckName: deckName,
                        cardId: cardId
                    )
                    print("🎯 WidgetDataService: Found new card for widget: \(question)")
                    return
                }
            } catch {
                print("Error fetching new cards for widget: \(error)")
            }

            // Second priority: Get due cards if no new cards
            let dueRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
            let dueCardPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "ANY reviewSessions.nextReview <= %@", now as NSDate),
                silencedDeckFilterPredicate()
            ])
            dueRequest.predicate = dueCardPredicate
            dueRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Flashcard.createdAt, ascending: true)]
            dueRequest.fetchLimit = 1

            do {
                let dueCards = try context.fetch(dueRequest)
                if let card = dueCards.first,
                   let question = card.question,
                   let answer = card.answer,
                   let deckName = card.deck?.name,
                   let cardId = card.id {
                    topCard = WidgetCardData(
                        question: question,
                        answer: answer,
                        deckName: deckName,
                        cardId: cardId
                    )
                    print("🎯 WidgetDataService: Found due card for widget: \(question)")
                }
            } catch {
                print("Error fetching due cards for widget: \(error)")
            }
        }

        return topCard
    }

    private func silencedDeckFilterPredicate() -> NSPredicate {
        let now = Date()

        // Deck should not be silenced, or if silenced, should be past the silence end date
        return NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "deck.isSilenced == NO"),
            NSPredicate(format: "deck.isSilenced == YES AND deck.silenceEndDate != nil AND deck.silenceEndDate <= %@", now as NSDate)
        ])
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

        print("🎯 WidgetDataService Debug:")
        print("  - Due Count: \(dueCount)")
        print("  - Has Cards: \(hasCards)")
        print("  - Last Updated: \(lastUpdated?.description ?? "Never")")
        print("  - Has Top Card: \(hasTopCard)")
        if hasTopCard {
            print("  - Top Card Question: \(topCardQuestion ?? "N/A")")
            print("  - Top Card Deck: \(topCardDeckName ?? "N/A")")
        }
        print("  - Using App Group: group.collect.software.cognition-curator")
    }
}
