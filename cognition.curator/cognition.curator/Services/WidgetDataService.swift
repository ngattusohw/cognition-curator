//
//  WidgetDataService.swift
//  cognition.curator
//
//  Created by Assistant on 7/27/25.
//

import Foundation
import CoreData
import WidgetKit

class WidgetDataService {
    static let shared = WidgetDataService()

    private let sharedDefaults: UserDefaults

    private init() {
        // Use App Groups to share data with widget
        self.sharedDefaults = UserDefaults(suiteName: "group.collect.software.cognition-curator")
                             ?? UserDefaults.standard
    }

    /// Update widget with current due card counts
    func updateWidgetData() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }

            let counts = self.getDueCardCounts()

            // Debug logging
            print("🎯 WidgetDataService: Updating widget data - Due: \(counts.dueCount), HasCards: \(counts.hasCards)")

            // Update shared UserDefaults
            self.sharedDefaults.set(counts.dueCount, forKey: "widget.dueCardsCount")
            self.sharedDefaults.set(counts.hasCards, forKey: "widget.hasCards")
            self.sharedDefaults.set(Date(), forKey: "widget.lastUpdated")

            // Force synchronization
            self.sharedDefaults.synchronize()

            DispatchQueue.main.async {
                // Force widget reload
                WidgetCenter.shared.reloadAllTimelines()
                print("🎯 WidgetDataService: Widget timeline reloaded")
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

        print("🎯 WidgetDataService Debug:")
        print("  - Due Count: \(dueCount)")
        print("  - Has Cards: \(hasCards)")
        print("  - Last Updated: \(lastUpdated?.description ?? "Never")")
        print("  - Using App Group: group.collect.software.cognition-curator")
    }
}
