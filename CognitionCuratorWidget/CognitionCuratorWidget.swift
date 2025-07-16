import WidgetKit
import SwiftUI
import CoreData

struct ReviewQuestionEntry: TimelineEntry {
    let date: Date
    let question: String
    let answer: String
    let deckName: String
    let cardId: UUID?
    let hasContent: Bool
}

struct ReviewQuestionProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReviewQuestionEntry {
        ReviewQuestionEntry(
            date: Date(),
            question: "What is the capital of France?",
            answer: "Paris",
            deckName: "Geography",
            cardId: nil,
            hasContent: true
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ReviewQuestionEntry) -> ()) {
        let entry = getNextReviewQuestion()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ReviewQuestionEntry>) -> ()) {
        let currentEntry = getNextReviewQuestion()
        
        // Update widget every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func getNextReviewQuestion() -> ReviewQuestionEntry {
        let container = PersistenceController.shared.container
        let context = container.viewContext
        
        // Fetch cards that are due for review
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        
        // Predicate to find cards that need review
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        
        request.predicate = NSPredicate(format: "reviewSessions.@count > 0 AND ANY reviewSessions.nextReview <= %@", now as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Flashcard.reviewSessions.nextReview, ascending: true)
        ]
        request.fetchLimit = 1
        
        do {
            let cards = try context.fetch(request)
            
            if let card = cards.first {
                return ReviewQuestionEntry(
                    date: Date(),
                    question: card.question ?? "No question available",
                    answer: card.answer ?? "No answer available",
                    deckName: card.deck?.name ?? "Unknown Deck",
                    cardId: card.id,
                    hasContent: true
                )
            }
        } catch {
            print("Widget: Error fetching review cards: \(error)")
        }
        
        // If no cards are due, get a random card for practice
        let fallbackRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        fallbackRequest.fetchLimit = 1
        
        do {
            let allCards = try context.fetch(fallbackRequest)
            if let card = allCards.randomElement() {
                return ReviewQuestionEntry(
                    date: Date(),
                    question: card.question ?? "No question available",
                    answer: card.answer ?? "No answer available", 
                    deckName: card.deck?.name ?? "Unknown Deck",
                    cardId: card.id,
                    hasContent: true
                )
            }
        } catch {
            print("Widget: Error fetching fallback cards: \(error)")
        }
        
        // Default empty state
        return ReviewQuestionEntry(
            date: Date(),
            question: "No cards available",
            answer: "Add some flashcards to get started!",
            deckName: "Cognition Curator",
            cardId: nil,
            hasContent: false
        )
    }
}

struct ReviewQuestionWidgetEntryView: View {
    var entry: ReviewQuestionProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: ReviewQuestionEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.3, green: 0.6, blue: 1.0),
                        Color(red: 0.2, green: 0.4, blue: 0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.white)
                        .font(.title2)
                    
                    Spacer()
                    
                    if entry.hasContent {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                Text(entry.hasContent ? "Review Time!" : "No Cards")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if entry.hasContent {
                    Text(entry.question)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Text(entry.deckName)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            .padding()
        }
        .widgetURL(deepLinkURL)
    }
    
    private var deepLinkURL: URL? {
        guard let cardId = entry.cardId else {
            return URL(string: "cognitioncurator://review")
        }
        return URL(string: "cognitioncurator://review/\(cardId.uuidString)")
    }
}

struct MediumWidgetView: View {
    let entry: ReviewQuestionEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.3, green: 0.6, blue: 1.0),
                        Color(red: 0.2, green: 0.4, blue: 0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.white)
                                .font(.title2)
                            
                            Text(entry.hasContent ? "Review Time!" : "No Cards Available")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        
                        Text(entry.deckName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if entry.hasContent {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.title2)
                    }
                }
                
                if entry.hasContent {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(entry.question)
                            .font(.body)
                            .foregroundColor(.white)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                        
                        Text("Tap to reveal answer and continue review")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    Text("Add some flashcards to get started with spaced repetition learning!")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                }
            }
            .padding()
        }
        .widgetURL(deepLinkURL)
    }
    
    private var deepLinkURL: URL? {
        guard let cardId = entry.cardId else {
            return URL(string: "cognitioncurator://review")
        }
        return URL(string: "cognitioncurator://review/\(cardId.uuidString)")
    }
}

struct LargeWidgetView: View {
    let entry: ReviewQuestionEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.3, green: 0.6, blue: 1.0),
                        Color(red: 0.2, green: 0.4, blue: 0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.white)
                                .font(.largeTitle)
                            
                            VStack(alignment: .leading) {
                                Text(entry.hasContent ? "Review Time!" : "No Cards Available")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(entry.deckName)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                        }
                    }
                    
                    if entry.hasContent {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.largeTitle)
                    }
                }
                
                if entry.hasContent {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Question:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(entry.question)
                            .font(.title3)
                            .foregroundColor(.white)
                            .lineLimit(5)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Answer Preview:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text(entry.answer)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.6))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                        }
                        
                        Text("Tap to open review session")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 8)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Get Started")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Add some flashcards to begin your spaced repetition learning journey. The widget will show your next review question when cards are due.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Text("Tap to open Cognition Curator")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding()
        }
        .widgetURL(deepLinkURL)
    }
    
    private var deepLinkURL: URL? {
        guard let cardId = entry.cardId else {
            return URL(string: "cognitioncurator://review")
        }
        return URL(string: "cognitioncurator://review/\(cardId.uuidString)")
    }
}

struct CognitionCuratorWidget: Widget {
    let kind: String = "CognitionCuratorWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReviewQuestionProvider()) { entry in
            ReviewQuestionWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Review Question")
        .description("Shows your next flashcard question ready for review.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct CognitionCuratorWidgetBundle: WidgetBundle {
    var body: some Widget {
        CognitionCuratorWidget()
    }
}

#Preview(as: .systemSmall) {
    CognitionCuratorWidget()
} timeline: {
    ReviewQuestionEntry(
        date: Date(),
        question: "What is the capital of France?",
        answer: "Paris",
        deckName: "Geography",
        cardId: UUID(),
        hasContent: true
    )
    ReviewQuestionEntry(
        date: Date(),
        question: "What is 2 + 2?",
        answer: "4", 
        deckName: "Math Basics",
        cardId: UUID(),
        hasContent: true
    )
}

#Preview(as: .systemMedium) {
    CognitionCuratorWidget()
} timeline: {
    ReviewQuestionEntry(
        date: Date(),
        question: "What is the capital of France and what is its most famous landmark?",
        answer: "Paris, and the Eiffel Tower",
        deckName: "Geography",
        cardId: UUID(),
        hasContent: true
    )
}

#Preview(as: .systemLarge) {
    CognitionCuratorWidget()
} timeline: {
    ReviewQuestionEntry(
        date: Date(),
        question: "Explain the process of photosynthesis in plants and why it's important for life on Earth?",
        answer: "Photosynthesis is the process by which plants convert light energy into chemical energy, producing oxygen as a byproduct which is essential for most life forms.",
        deckName: "Biology",
        cardId: UUID(),
        hasContent: true
    )
} 