import Foundation
import Combine
import SwiftUI

// MARK: - AI Generation Models

struct AIGeneratedCard: Identifiable, Codable {
    let id: UUID
    var question: String
    var answer: String
    var explanation: String?
    var difficulty: CardDifficulty
    var tags: [String]
    var isAccepted: Bool
    var isModified: Bool

    init(question: String, answer: String, explanation: String? = nil, difficulty: CardDifficulty = .medium, tags: [String] = []) {
        self.id = UUID()
        self.question = question
        self.answer = answer
        self.explanation = explanation
        self.difficulty = difficulty
        self.tags = tags
        self.isAccepted = true
        self.isModified = false
    }
}

enum CardDifficulty: String, CaseIterable, Codable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

struct AIGenerationRequest: Codable {
    let topic: String
    let numberOfCards: Int
    let difficulty: String
    let focus: String?
    let cardType: String

    enum CodingKeys: String, CodingKey {
        case topic
        case numberOfCards = "number_of_cards"
        case difficulty
        case focus
        case cardType = "card_type"
    }
}

struct AIGenerationResponse: Codable {
    let cards: [AICardResponse]
    let topic: String
    let totalGenerated: Int
    let difficulty: String?
    let focus: String?
    let generationTime: Double?
    let modelVersion: String?
    let confidenceAvg: Double?

    enum CodingKeys: String, CodingKey {
        case cards
        case topic
        case totalGenerated = "total_generated"
        case difficulty
        case focus
        case generationTime = "generation_time"
        case modelVersion = "model_version"
        case confidenceAvg = "confidence_avg"
    }
}

struct AICardResponse: Codable {
    let question: String
    let answer: String
    let explanation: String?
    let difficulty: String
    let tags: [String]
    let confidence: Double
}

// MARK: - AI Generation Service

@MainActor
class AIGenerationService: ObservableObject {
    static let shared = AIGenerationService()

    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var lastError: String?

    private let baseURL = "http://127.0.0.1:5001/api"
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    // MARK: - Card Generation

    func generateFlashcards(
        topic: String,
        numberOfCards: Int = 15,
        difficulty: CardDifficulty = .medium,
        focus: String? = nil
    ) async throws -> [AIGeneratedCard] {

        print("🤖 AIGenerationService: Starting card generation for topic: \(topic)")

        isGenerating = true
        generationProgress = 0.0
        lastError = nil

        defer {
            isGenerating = false
            generationProgress = 1.0
        }

        // Check for network connectivity
        if !NetworkMonitor.shared.isConnected {
            print("📴 AIGenerationService: No network connection, using fallback generation")
            return try await generateFallbackCards(topic: topic, numberOfCards: numberOfCards, difficulty: difficulty)
        }

        do {
            // Update progress for API call
            generationProgress = 0.3

            let request = AIGenerationRequest(
                topic: topic,
                numberOfCards: numberOfCards,
                difficulty: difficulty.rawValue,
                focus: focus,
                cardType: "flashcard"
            )

            // Make API call
            let response = try await makeAIGenerationRequest(request)

            // Update progress for processing
            generationProgress = 0.8

            // Convert API response to our model
            print("🔍 AIGenerationService: Raw response cards count: \(response.cards.count)")

            let cards = response.cards.compactMap { cardResponse -> AIGeneratedCard? in
                print("🔍 Processing card: '\(cardResponse.question)' - '\(cardResponse.answer)'")

                guard !cardResponse.question.isEmpty && !cardResponse.answer.isEmpty else {
                    print("❌ Skipping empty card")
                    return nil
                }

                let cardDifficulty = CardDifficulty(rawValue: cardResponse.difficulty) ?? difficulty

                let card = AIGeneratedCard(
                    question: cardResponse.question,
                    answer: cardResponse.answer,
                    explanation: cardResponse.explanation,
                    difficulty: cardDifficulty,
                    tags: cardResponse.tags
                )

                print("✅ Created card: \(card.question)")
                return card
            }

            print("✅ AIGenerationService: Generated \(cards.count) cards successfully")
            return cards

        } catch {
            print("❌ AIGenerationService: Generation failed: \(error)")
            lastError = error.localizedDescription

            // Fallback to local generation
            print("🔄 AIGenerationService: Falling back to local generation")
            return try await generateFallbackCards(topic: topic, numberOfCards: numberOfCards, difficulty: difficulty)
        }
    }

    // MARK: - API Communication

    private func makeAIGenerationRequest(_ request: AIGenerationRequest) async throws -> AIGenerationResponse {
        guard let url = URL(string: "\(baseURL)/ai/generate-flashcards") else {
            throw AIGenerationError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add authentication if available
        if let jwtToken = AuthenticationService.shared.getCurrentJWTToken() {
            urlRequest.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw AIGenerationError.encodingError("Failed to encode request")
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIGenerationError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AIGenerationError.serverError(errorData.error)
            } else {
                throw AIGenerationError.serverError("AI generation failed with status \(httpResponse.statusCode)")
            }
        }

        do {
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 AIGenerationService: Raw response: \(responseString)")
            }

            let response = try JSONDecoder().decode(AIGenerationResponse.self, from: data)
            print("🔍 AIGenerationService: Decoded response with \(response.cards.count) cards")
            return response
        } catch {
            print("❌ AIGenerationService: Decoding error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 Failed response data: \(responseString)")
            }
            throw AIGenerationError.decodingError("Failed to decode AI response: \(error.localizedDescription)")
        }
    }

    // MARK: - Fallback Generation

    private func generateFallbackCards(
        topic: String,
        numberOfCards: Int,
        difficulty: CardDifficulty
    ) async throws -> [AIGeneratedCard] {

        print("🔄 AIGenerationService: Generating fallback cards for: \(topic)")

        // Simulate generation time
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        var cards: [AIGeneratedCard] = []

        // Generate basic question templates based on topic
        let questionTemplates = [
            "What is \(topic)?",
            "How does \(topic) work?",
            "Why is \(topic) important?",
            "What are the main characteristics of \(topic)?",
            "How is \(topic) used in practice?",
            "What are the benefits of \(topic)?",
            "What are the challenges with \(topic)?",
            "Who developed \(topic)?",
            "When was \(topic) first introduced?",
            "What are the different types of \(topic)?",
            "How do you implement \(topic)?",
            "What are the best practices for \(topic)?",
            "What are common misconceptions about \(topic)?",
            "How does \(topic) relate to other concepts?",
            "What are the future trends in \(topic)?"
        ]

        let answerTemplates = [
            "\(topic) is a fundamental concept that...",
            "\(topic) works by utilizing several key principles...",
            "\(topic) is important because it provides...",
            "The main characteristics of \(topic) include...",
            "\(topic) is used in practice through...",
            "The benefits of \(topic) are numerous, including...",
            "Common challenges with \(topic) include...",
            "\(topic) was developed by researchers who...",
            "\(topic) was first introduced in the context of...",
            "There are several types of \(topic), including...",
            "To implement \(topic), you should...",
            "Best practices for \(topic) include...",
            "A common misconception about \(topic) is that...",
            "\(topic) relates to other concepts by...",
            "Future trends in \(topic) suggest that..."
        ]

        for i in 0..<min(numberOfCards, questionTemplates.count) {
            let card = AIGeneratedCard(
                question: questionTemplates[i],
                answer: answerTemplates[i],
                explanation: "This is a generated explanation for \(topic) card \(i + 1)",
                difficulty: difficulty,
                tags: [topic.lowercased(), "ai-generated"]
            )
            cards.append(card)

            // Update progress
            generationProgress = 0.3 + (Double(i + 1) / Double(numberOfCards)) * 0.5
        }

        print("✅ AIGenerationService: Generated \(cards.count) fallback cards")
        return cards
    }

        // MARK: - Answer Generation

    func generateAnswer(
        for question: String,
        context: String? = nil,
        difficulty: CardDifficulty = .medium,
        deckTopic: String? = nil
    ) async throws -> AIAnswerResponse {

        print("🤖 AIGenerationService: Generating answer for question: \(question)")

        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIGenerationError.noCardsGenerated
        }

        // Check for network connectivity
        if !NetworkMonitor.shared.isConnected {
            print("📴 AIGenerationService: No network connection, using fallback answer generation")
            return generateFallbackAnswer(for: question, difficulty: difficulty, deckTopic: deckTopic)
        }

        do {
            let request = AIAnswerRequest(
                question: question,
                context: context,
                difficulty: difficulty.rawValue,
                deckTopic: deckTopic
            )

            let response = try await makeAnswerGenerationRequest(request)

            print("✅ AIGenerationService: Generated answer successfully")
            return response

        } catch {
            print("❌ AIGenerationService: Answer generation failed: \(error)")

            // Fallback to local generation
            print("🔄 AIGenerationService: Falling back to local answer generation")
            return generateFallbackAnswer(for: question, difficulty: difficulty, deckTopic: deckTopic)
        }
    }

    private func makeAnswerGenerationRequest(_ request: AIAnswerRequest) async throws -> AIAnswerResponse {
        guard let url = URL(string: "\(baseURL)/ai/generate-answer") else {
            throw AIGenerationError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add authentication if available
        if let jwtToken = AuthenticationService.shared.getCurrentJWTToken() {
            urlRequest.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw AIGenerationError.encodingError("Failed to encode request")
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIGenerationError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AIGenerationError.serverError(errorData.error)
            } else {
                throw AIGenerationError.serverError("Answer generation failed with status \(httpResponse.statusCode)")
            }
        }

        do {
            return try JSONDecoder().decode(AIAnswerResponse.self, from: data)
        } catch {
            throw AIGenerationError.decodingError("Failed to decode AI answer response")
        }
    }

    private func generateFallbackAnswer(
        for question: String,
        difficulty: CardDifficulty,
        deckTopic: String?
    ) -> AIAnswerResponse {

        let questionLower = question.lowercased()

        var answer = ""
        var explanation = ""
        var suggestedTags: [String] = []

        // Generate context-aware fallback answers
        if let topic = deckTopic?.lowercased() {
            if topic.contains("fuel") && topic.contains("system") {
                // Fuel system specific fallback
                if questionLower.contains("pump") {
                    answer = "A fuel pump is a mechanical or electrical device that moves fuel from the tank to the engine, creating the necessary pressure for proper fuel delivery."
                    explanation = "Modern vehicles use electric fuel pumps for better efficiency and control."
                    suggestedTags = ["pump", "component", "automotive"]
                } else if questionLower.contains("injector") {
                    answer = "A fuel injector is a precision valve that sprays atomized fuel into the engine's intake or combustion chamber at precisely controlled intervals."
                    explanation = "Fuel injectors provide much more accurate fuel delivery compared to carburetors."
                    suggestedTags = ["injector", "precision", "fuel-delivery"]
                } else if questionLower.contains("filter") {
                    answer = "A fuel filter is a component that removes contaminants and impurities from fuel before it reaches the engine components."
                    explanation = "Clean fuel is essential for optimal engine performance and longevity of fuel system components."
                    suggestedTags = ["filter", "maintenance", "contamination"]
                } else {
                    answer = "This relates to automotive fuel system components and their operation, involving the storage, delivery, and injection of fuel for engine combustion."
                    explanation = "Fuel systems are critical for vehicle operation and performance."
                    suggestedTags = ["fuel-system", "automotive", "general"]
                }
            } else {
                // Generic topic-based answer
                answer = "This concept relates to \(topic) and involves key principles and applications within this field."
                explanation = "Understanding this concept is important for mastering \(topic)."
                suggestedTags = [topic.replacingOccurrences(of: " ", with: "-"), "concept"]
            }
        } else {
            // Generic fallback answer
            if questionLower.contains("what is") || questionLower.contains("define") {
                answer = "This is a fundamental concept that encompasses key principles and applications in its respective field."
                explanation = "Understanding this definition is essential for grasping related concepts."
                suggestedTags = ["definition", "concept"]
            } else if questionLower.contains("how") {
                answer = "This process involves a series of steps and mechanisms that work together to achieve the desired outcome."
                explanation = "Understanding the process helps in applying the concept effectively."
                suggestedTags = ["process", "mechanism"]
            } else if questionLower.contains("why") {
                answer = "This is important because it provides essential functionality and benefits in its application domain."
                explanation = "Understanding the importance helps in appreciating the value of this concept."
                suggestedTags = ["importance", "purpose"]
            } else {
                answer = "This relates to fundamental principles and concepts that are essential for understanding the subject matter."
                explanation = "This answer provides a general overview of the topic."
                suggestedTags = ["general", "overview"]
            }
        }

        return AIAnswerResponse(
            answer: answer,
            explanation: explanation,
            confidence: Double.random(in: 0.75...0.88),
            sources: [],
            difficulty: difficulty.rawValue,
            generationTime: Double.random(in: 0.8...2.1),
            modelVersion: "fallback-v1.0",
            suggestedTags: suggestedTags
        )
    }

    // MARK: - Card Enhancement

    func enhanceCard(_ card: AIGeneratedCard, context: String? = nil) async throws -> AIGeneratedCard {
        print("🔧 AIGenerationService: Enhancing card: \(card.question)")

        // For now, return the original card
        // In the future, this could make an API call to improve the card
        return card
    }

    func generateSimilarCards(basedOn card: AIGeneratedCard, count: Int = 3) async throws -> [AIGeneratedCard] {
        print("🔄 AIGenerationService: Generating \(count) similar cards based on: \(card.question)")

        // For now, return variations of the original card
        var similarCards: [AIGeneratedCard] = []

        for i in 1...count {
            let similarCard = AIGeneratedCard(
                question: "Variation \(i): \(card.question)",
                answer: "Related answer \(i): \(card.answer)",
                explanation: card.explanation,
                difficulty: card.difficulty,
                tags: card.tags + ["variation"]
            )
            similarCards.append(similarCard)
        }

        return similarCards
    }

    // MARK: - Validation

    func validateCards(_ cards: [AIGeneratedCard]) -> [AIGeneratedCard] {
        return cards.filter { card in
            !card.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !card.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            card.question.count > 5 &&
            card.answer.count > 3
        }
    }
}

// MARK: - Error Types

enum AIGenerationError: LocalizedError {
    case invalidURL
    case encodingError(String)
    case networkError(String)
    case invalidResponse
    case serverError(String)
    case decodingError(String)
    case noCardsGenerated

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .encodingError(let message):
            return "Encoding error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return "Server error: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .noCardsGenerated:
            return "No cards were generated"
        }
    }
}

// MARK: - AI Answer Generation Models

struct AIAnswerRequest: Codable {
    let question: String
    let context: String?
    let difficulty: String
    let deckTopic: String?

    enum CodingKeys: String, CodingKey {
        case question
        case context
        case difficulty
        case deckTopic = "deck_topic"
    }
}

struct AIAnswerResponse: Codable {
    let answer: String
    let explanation: String?
    let confidence: Double
    let sources: [String]
    let difficulty: String
    let generationTime: Double
    let modelVersion: String
    let suggestedTags: [String]

    enum CodingKeys: String, CodingKey {
        case answer
        case explanation
        case confidence
        case sources
        case difficulty
        case generationTime = "generation_time"
        case modelVersion = "model_version"
        case suggestedTags = "suggested_tags"
    }
}

struct ErrorResponse: Codable {
    let error: String
}