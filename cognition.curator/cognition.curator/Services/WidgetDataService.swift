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
        let counts = getDueCardCounts()

        // Update shared UserDefaults
        sharedDefaults.set(counts.dueCount, forKey: "widget.dueCardsCount")
        sharedDefaults.set(counts.hasCards, forKey: "widget.hasCards")
        sharedDefaults.set(Date(), forKey: "widget.lastUpdated")

        // Force widget reload
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func getDueCardCounts() -> (dueCount: Int, hasCards: Bool) {
        let context = PersistenceController.shared.container.viewContext
        let now = Date()

        // Count NEW cards (no review sessions)
        let newRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        newRequest.predicate = NSPredicate(format: "reviewSessions.@count == 0")
        let newCount = (try? context.count(for: newRequest)) ?? 0

        // Count DUE cards (ready for review)
        let dueRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        dueRequest.predicate = NSPredicate(format: "ANY reviewSessions.nextReview <= %@", now as NSDate)
        let dueCount = (try? context.count(for: dueRequest)) ?? 0

        let totalDue = newCount + dueCount
        let hasCards = totalDue > 0

        return (dueCount: totalDue, hasCards: hasCards)
    }

    /// Call this when app becomes active to refresh widget data
    func refreshOnAppLaunch() {
        updateWidgetData()
    }

    /// Call this after completing reviews to update counts
    func refreshAfterReview() {
        updateWidgetData()
    }

    /// Call this when new cards are added
    func refreshAfterAddingCards() {
        updateWidgetData()
    }
}
