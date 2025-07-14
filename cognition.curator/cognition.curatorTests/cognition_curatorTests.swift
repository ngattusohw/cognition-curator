//
//  cognition_curatorTests.swift
//  cognition.curatorTests
//
//  Created by Nicholas Gattuso on 7/13/25.
//

import XCTest
import SwiftUI
import CoreData
@testable import cognition_curator

final class CognitionCuratorTests: XCTestCase {
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController.preview
        context = persistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        context = nil
    }
    
    // MARK: - Core Data Tests
    func testDeckCreation() throws {
        let deck = Deck(context: context)
        deck.name = "Test Deck"
        deck.createdAt = Date()
        
        try context.save()
        
        XCTAssertEqual(deck.name, "Test Deck")
        XCTAssertNotNil(deck.createdAt)
    }
    
    func testFlashcardCreation() throws {
        let deck = Deck(context: context)
        deck.name = "Test Deck"
        
        let card = Flashcard(context: context)
        card.question = "What is 2+2?"
        card.answer = "4"
        card.deck = deck
        card.createdAt = Date()
        
        try context.save()
        
        XCTAssertEqual(card.question, "What is 2+2?")
        XCTAssertEqual(card.answer, "4")
        XCTAssertEqual(card.deck, deck)
        XCTAssertEqual(deck.flashcards?.count, 1)
    }
    
    // MARK: - Spaced Repetition Tests
    func testSpacedRepetitionCalculation() throws {
        let card = Flashcard(context: context)
        card.question = "Test"
        card.answer = "Test"
        card.createdAt = Date()
        
        let nextReview = SpacedRepetitionService.shared.calculateNextReview(for: card, difficulty: 3)
        
        XCTAssertNotNil(nextReview)
        XCTAssertTrue(nextReview > Date())
    }
    
    func testReviewSessionCreation() throws {
        let card = Flashcard(context: context)
        card.question = "Test"
        card.answer = "Test"
        
        let session = ReviewSession(context: context)
        session.difficulty = 3
        session.reviewedAt = Date()
        session.nextReview = Date().addingTimeInterval(86400) // 1 day
        session.flashcard = card
        
        try context.save()
        
        XCTAssertEqual(session.difficulty, 3)
        XCTAssertEqual(session.flashcard, card)
        XCTAssertEqual(card.reviewSessions?.count, 1)
    }
    
    // MARK: - Progress Calculation Tests
    func testProgressCalculation() throws {
        let deck = Deck(context: context)
        deck.name = "Test Deck"
        
        // Create cards
        for i in 1...10 {
            let card = Flashcard(context: context)
            card.question = "Question \(i)"
            card.answer = "Answer \(i)"
            card.deck = deck
            
            // Mark first 5 as reviewed
            if i <= 5 {
                let session = ReviewSession(context: context)
                session.difficulty = 3
                session.reviewedAt = Date()
                session.nextReview = Date().addingTimeInterval(86400)
                session.flashcard = card
            }
        }
        
        try context.save()
        
        // Test progress calculation
        let cards = deck.flashcards?.allObjects as? [Flashcard] ?? []
        let reviewedCards = cards.filter { !($0.reviewSessions?.allObjects.isEmpty ?? true) }
        let progress = Double(reviewedCards.count) / Double(cards.count)
        
        XCTAssertEqual(progress, 0.5) // 5/10 = 50%
    }
    
    // MARK: - View State Tests
    func testDeckDetailViewState() throws {
        let deck = Deck(context: context)
        deck.name = "Test Deck"
        
        // Create some cards
        for i in 1...3 {
            let card = Flashcard(context: context)
            card.question = "Question \(i)"
            card.answer = "Answer \(i)"
            card.deck = deck
        }
        
        try context.save()
        
        // Test filtered cards logic
        let cards = deck.flashcards?.allObjects as? [Flashcard] ?? []
        let sortedCards = cards.sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date() }
        
        XCTAssertEqual(sortedCards.count, 3)
    }
    
    // MARK: - Navigation Tests
    func testNavigationPaths() throws {
        // Test that all required navigation destinations exist
        let deck = Deck(context: context)
        deck.name = "Test Deck"
        
        // These should not crash
        XCTAssertNoThrow(DeckDetailView(deck: deck))
        XCTAssertNoThrow(AddCardView(deck: deck))
        XCTAssertNoThrow(EditDeckView(deck: deck))
    }
    
    // MARK: - Data Integrity Tests
    func testDataIntegrity() throws {
        let deck = Deck(context: context)
        deck.name = "Test Deck"
        
        let card = Flashcard(context: context)
        card.question = "Test Question"
        card.answer = "Test Answer"
        card.deck = deck
        
        try context.save()
        
        // Test relationships
        XCTAssertEqual(card.deck, deck)
        XCTAssertTrue(deck.flashcards?.contains(card) ?? false)
        
        // Test deletion cascade - save the card's object ID before deletion
        let cardObjectID = card.objectID
        context.delete(deck)
        try context.save()
        
        // After saving, the card should be deleted due to cascade delete
        // Check if the card is deleted by trying to fetch it
        do {
            let fetchedCard = try context.existingObject(with: cardObjectID)
            XCTFail("Card should have been deleted when deck was deleted, but it still exists: \(fetchedCard)")
        } catch {
            // This is expected - the card should not exist anymore
            XCTAssertTrue(true, "Card was properly deleted when deck was deleted")
        }
    }
    
    // MARK: - Performance Tests
    func testPerformance() throws {
        measure {
            let deck = Deck(context: context)
            deck.name = "Performance Test"
            
            // Create many cards
            for i in 1...1000 {
                let card = Flashcard(context: context)
                card.question = "Question \(i)"
                card.answer = "Answer \(i)"
                card.deck = deck
            }
            
            try! context.save()
        }
    }
}
