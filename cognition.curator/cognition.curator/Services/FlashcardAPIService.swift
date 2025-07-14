import Foundation

// MARK: - API Service Protocol
protocol FlashcardAPIService {
    func generateDeck(topic: String) async throws -> [Flashcard]
    func enhanceCard(card: Flashcard) async throws -> Flashcard
}

// MARK: - LangGraph API Service Implementation
class LangGraphAPIService: FlashcardAPIService {
    private let baseURL = "https://api.langgraph.com" // Replace with actual LangGraph API endpoint
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateDeck(topic: String) async throws -> [Flashcard] {
        // TODO: Implement actual LangGraph API call
        // For now, return mock data
        return [
            FlashcardData(question: "What is \(topic)?", answer: "A concept related to \(topic)"),
            FlashcardData(question: "How does \(topic) work?", answer: "It works through various mechanisms"),
            FlashcardData(question: "Why is \(topic) important?", answer: "Because it provides value in many contexts")
        ].map { cardData in
            let card = Flashcard()
            card.question = cardData.question
            card.answer = cardData.answer
            card.id = UUID()
            card.createdAt = Date()
            return card
        }
    }
    
    func enhanceCard(card: Flashcard) async throws -> Flashcard {
        // TODO: Implement actual LangGraph API call for card enhancement
        // For now, return the original card
        return card
    }
}

// MARK: - Mock Data Structure
struct FlashcardData {
    let question: String
    let answer: String
}

// MARK: - API Error Types
enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case unauthorized
    case serverError(String)
} 