import SwiftUI
import SwiftData

struct PreviewHelper {
    static let shared = PreviewHelper()
    
    // MARK: - Test Data Generation
    @MainActor
    static func createSampleDeck(name: String = "Sample Deck", cardCount: Int = 5, reviewedCount: Int = 2) -> Deck {
        let context = PersistenceController.preview.mainContext
        let deck = Deck(
            name: name,
            createdAt: Date(),
            isPremium: false,
            isSuperset: false
        )
        context.insert(deck)
        
        // Create cards
        for i in 1...cardCount {
            let card = Flashcard(
                question: "Sample Question \(i)",
                answer: "Sample Answer \(i)",
                createdAt: Date().addingTimeInterval(-Double(i * 3600)),
                deck: deck
            )
            context.insert(card)
            
            // Mark some as reviewed
            if i <= reviewedCount {
                let session = ReviewSession(
                    difficulty: Int16([1, 2, 3, 4].randomElement() ?? 3),
                    easeFactor: 2.5,
                    interval: Double(i * 86400) / 1440.0, // Convert to minutes
                    reviewedAt: Date().addingTimeInterval(-Double(i * 1800)),
                    nextReview: Date().addingTimeInterval(Double(i * 86400)),
                    flashcard: card
                )
                context.insert(session)
            }
        }
        
        return deck
    }
    
    @MainActor
    static func createEmptyDeck() -> Deck {
        return createSampleDeck(name: "Empty Deck", cardCount: 0, reviewedCount: 0)
    }
    
    @MainActor
    static func createFullDeck() -> Deck {
        return createSampleDeck(name: "Full Deck", cardCount: 20, reviewedCount: 15)
    }
    
    @MainActor
    static func createPremiumDeck() -> Deck {
        let context = PersistenceController.preview.mainContext
        let deck = Deck(
            name: "Premium Deck",
            createdAt: Date(),
            isPremium: true,
            isSuperset: false
        )
        context.insert(deck)
        
        for i in 1...10 {
            let card = Flashcard(
                question: "Premium Question \(i)",
                answer: "Premium Answer \(i)",
                createdAt: Date(),
                deck: deck
            )
            context.insert(card)
            
            if i <= 5 {
                let session = ReviewSession(
                    difficulty: Int16([1, 2, 3, 4].randomElement() ?? 3),
                    easeFactor: 2.5,
                    interval: 1440.0,
                    reviewedAt: Date(),
                    flashcard: card
                )
                context.insert(session)
            }
        }
        
        return deck
    }
    
    @MainActor
    static func createSupersetDeck() -> Deck {
        let context = PersistenceController.preview.mainContext
        let deck = Deck(
            name: "Superset Deck",
            createdAt: Date(),
            isPremium: false,
            isSuperset: true
        )
        context.insert(deck)
        
        for i in 1...8 {
            let card = Flashcard(
                question: "Superset Question \(i)",
                answer: "Superset Answer \(i)",
                createdAt: Date(),
                deck: deck
            )
            context.insert(card)
            
            if i <= 3 {
                let session = ReviewSession(
                    difficulty: Int16([1, 2, 3, 4].randomElement() ?? 3),
                    easeFactor: 2.5,
                    interval: 1440.0,
                    reviewedAt: Date(),
                    flashcard: card
                )
                context.insert(session)
            }
        }
        
        return deck
    }
    
    // MARK: - UI State Testing
    @MainActor
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
        .modelContainer(PersistenceController.preview)
    }
}

extension DecksView {
    static var allStatePreviews: some View {
        VStack {
            Text("Decks View - All States")
                .font(.title)
            DecksView()
        }
        .modelContainer(PersistenceController.preview)
    }
}

extension ReviewView {
    static var allStatePreviews: some View {
        VStack {
            Text("Review View - All States")
                .font(.title)
            ReviewView(forceReview: .constant(false), selectedTab: .constant(0))
        }
        .modelContainer(PersistenceController.preview)
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
