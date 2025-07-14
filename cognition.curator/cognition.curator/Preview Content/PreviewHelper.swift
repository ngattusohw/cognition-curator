import SwiftUI
import CoreData

struct PreviewHelper {
    static let shared = PreviewHelper()
    
    // MARK: - Test Data Generation
    static func createSampleDeck(name: String = "Sample Deck", cardCount: Int = 5, reviewedCount: Int = 2) -> Deck {
        let context = PersistenceController.preview.container.viewContext
        let deck = Deck(context: context)
        deck.name = name
        deck.createdAt = Date()
        deck.isPremium = false
        deck.isSuperset = false
        
        // Create cards
        for i in 1...cardCount {
            let card = Flashcard(context: context)
            card.question = "Sample Question \(i)"
            card.answer = "Sample Answer \(i)"
            card.deck = deck
            card.createdAt = Date().addingTimeInterval(-Double(i * 3600))
            
            // Mark some as reviewed
            if i <= reviewedCount {
                let session = ReviewSession(context: context)
                session.difficulty = Int16([1, 2, 3, 4].randomElement() ?? 3)
                session.reviewedAt = Date().addingTimeInterval(-Double(i * 1800))
                session.nextReview = Date().addingTimeInterval(Double(i * 86400))
                session.flashcard = card
            }
        }
        
        return deck
    }
    
    static func createEmptyDeck() -> Deck {
        return createSampleDeck(name: "Empty Deck", cardCount: 0, reviewedCount: 0)
    }
    
    static func createFullDeck() -> Deck {
        return createSampleDeck(name: "Full Deck", cardCount: 20, reviewedCount: 15)
    }
    
    static func createPremiumDeck() -> Deck {
        let deck = createSampleDeck(name: "Premium Deck", cardCount: 10, reviewedCount: 5)
        deck.isPremium = true
        return deck
    }
    
    static func createSupersetDeck() -> Deck {
        let deck = createSampleDeck(name: "Superset Deck", cardCount: 8, reviewedCount: 3)
        deck.isSuperset = true
        return deck
    }
    
    // MARK: - UI State Testing
    static func testAllStates<T: View>(_ viewBuilder: @escaping (Deck) -> T) -> some View {
        VStack(spacing: 20) {
            Group {
                Text("Empty State")
                    .font(.headline)
                viewBuilder(createEmptyDeck())
                    .frame(height: 200)
                
                Text("Normal State")
                    .font(.headline)
                viewBuilder(createSampleDeck())
                    .frame(height: 200)
                
                Text("Full State")
                    .font(.headline)
                viewBuilder(createFullDeck())
                    .frame(height: 200)
            }
            
            Group {
                Text("Premium State")
                    .font(.headline)
                viewBuilder(createPremiumDeck())
                    .frame(height: 200)
                
                Text("Superset State")
                    .font(.headline)
                viewBuilder(createSupersetDeck())
                    .frame(height: 200)
            }
        }
        .padding()
    }
}

// MARK: - Comprehensive Preview Extensions
extension DeckDetailView {
    static var allStatePreviews: some View {
        PreviewHelper.testAllStates { deck in
            DeckDetailView(deck: deck)
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

extension DecksView {
    static var allStatePreviews: some View {
        VStack {
            Text("Decks View - All States")
                .font(.title)
            DecksView()
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

extension ReviewView {
    static var allStatePreviews: some View {
        VStack {
            Text("Review View - All States")
                .font(.title)
            ReviewView()
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

// MARK: - Preview Validation
struct PreviewValidator {
    static func validateAllPreviews() {
        // This would be called in tests to ensure all previews compile
        _ = DeckDetailView.allStatePreviews
        _ = DecksView.allStatePreviews
        _ = ReviewView.allStatePreviews
    }
} 