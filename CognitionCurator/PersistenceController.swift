import CoreData
import CloudKit

class PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for preview
        let sampleDeck = Deck(context: viewContext)
        sampleDeck.id = UUID()
        sampleDeck.name = "Sample Deck"
        sampleDeck.createdAt = Date()
        sampleDeck.isPremium = false
        sampleDeck.isSuperset = false
        
        let sampleCard1 = Flashcard(context: viewContext)
        sampleCard1.id = UUID()
        sampleCard1.question = "What is the capital of France?"
        sampleCard1.answer = "Paris"
        sampleCard1.createdAt = Date()
        sampleCard1.deck = sampleDeck
        
        let sampleCard2 = Flashcard(context: viewContext)
        sampleCard2.id = UUID()
        sampleCard2.question = "What is 2 + 2?"
        sampleCard2.answer = "4"
        sampleCard2.createdAt = Date()
        sampleCard2.deck = sampleDeck
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentCloudKitContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "CognitionCurator")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configure CloudKit for premium users
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
} 