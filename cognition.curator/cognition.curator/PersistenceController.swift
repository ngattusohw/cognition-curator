import Foundation
import SwiftData

class PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: ModelContainer = {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(
                for: Schema([Deck.self, Flashcard.self, ReviewSession.self, SyncOperation.self, User.self]),
                configurations: [config]
            )
            
            Task { @MainActor in
                let context = container.mainContext
                
                // Create sample data for preview
                let sampleDeck = Deck(
                    name: "Sample Deck",
                    createdAt: Date(),
                    isPremium: false,
                    isSuperset: false
                )
                
                let sampleCard1 = Flashcard(
                    question: "What is the capital of France?",
                    answer: "Paris",
                    createdAt: Date(),
                    deck: sampleDeck
                )
                
                let sampleCard2 = Flashcard(
                    question: "What is 2 + 2?",
                    answer: "4",
                    createdAt: Date(),
                    deck: sampleDeck
                )
                
                context.insert(sampleDeck)
                context.insert(sampleCard1)
                context.insert(sampleCard2)
            }
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()
    
    let container: ModelContainer
    
    init(inMemory: Bool = false) {
        let schema = Schema([
            Deck.self,
            Flashcard.self,
            ReviewSession.self,
            SyncOperation.self,
            User.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .automatic
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    @MainActor
    func save() {
        let context = container.mainContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
} 