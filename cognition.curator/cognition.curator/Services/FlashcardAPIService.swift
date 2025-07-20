import Foundation

// MARK: - Backend Models

struct BackendFlashcard: Codable {
    let id: String
    let deckId: String
    let front: String
    let back: String
    let hint: String?
    let explanation: String?
    let tags: [String]
    let isActive: Bool
    let status: String
    let aiGenerated: Bool
    let createdAt: String
    let updatedAt: String
    let lastReviewedAt: String?
    let nextReviewDate: String
    let isDue: Bool

    // Analytics fields
    let easeactor: Double?
    let intervalDays: Int?
    let repetitions: Int?
    let totalReviews: Int?
    let correctReviews: Int?
    let accuracyRate: Double?
    let streakCorrect: Int?
    let longestStreak: Int?
    let mistakeCount: Int?
    let totalStudyTimeSeconds: Int?
    let averageResponseTimeSeconds: Double?
    let perceivedDifficulty: Double?
    let learningVelocity: Double?
    let difficultyScore: Double?
    let masteryLevel: Double?

    enum CodingKeys: String, CodingKey {
        case id, front, back, hint, explanation, tags, status
        case deckId = "deck_id"
        case isActive = "is_active"
        case aiGenerated = "ai_generated"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastReviewedAt = "last_reviewed_at"
        case nextReviewDate = "next_review_date"
        case isDue = "is_due"
        case easeactor = "ease_factor"
        case intervalDays = "interval_days"
        case repetitions, totalReviews = "total_reviews"
        case correctReviews = "correct_reviews"
        case accuracyRate = "accuracy_rate"
        case streakCorrect = "streak_correct"
        case longestStreak = "longest_streak"
        case mistakeCount = "mistake_count"
        case totalStudyTimeSeconds = "total_study_time_seconds"
        case averageResponseTimeSeconds = "average_response_time_seconds"
        case perceivedDifficulty = "perceived_difficulty"
        case learningVelocity = "learning_velocity"
        case difficultyScore = "difficulty_score"
        case masteryLevel = "mastery_level"
    }
}

struct CreateFlashcardRequest: Codable {
    let deckId: String
    let front: String
    let back: String
    let hint: String?
    let explanation: String?
    let tags: [String]
    let sourceReference: String?

    enum CodingKeys: String, CodingKey {
        case front, back, hint, explanation, tags
        case deckId = "deck_id"
        case sourceReference = "source_reference"
    }
}

struct CreateFlashcardResponse: Codable {
    let flashcard: BackendFlashcard
}

struct GetFlashcardsResponse: Codable {
    let flashcards: [BackendFlashcard]
    let totalCount: Int

    enum CodingKeys: String, CodingKey {
        case flashcards
        case totalCount = "total_count"
    }
}

// MARK: - FlashcardAPIService

@MainActor
class FlashcardAPIService: ObservableObject {
    private let baseURL = "http://localhost:5001/api"
    private let authService: AuthenticationService

    init(authService: AuthenticationService) {
        self.authService = authService
    }

    // MARK: - API Methods

    func createFlashcard(
        deckId: String,
        front: String,
        back: String,
        hint: String? = nil,
        explanation: String? = nil,
        tags: [String] = [],
        sourceReference: String? = nil
    ) async throws -> BackendFlashcard {
        guard let jwtToken = authService.getCurrentJWTToken() else {
            print("❌ FlashcardAPIService: No JWT token found")
            throw FlashcardAPIError.notAuthenticated
        }

        print("✅ FlashcardAPIService: Creating flashcard with JWT token: \(String(jwtToken.prefix(20)))...")

        guard let url = URL(string: "\(baseURL)/flashcards/") else {
            throw FlashcardAPIError.invalidURL
        }

        let request = CreateFlashcardRequest(
            deckId: deckId,
            front: front,
            back: back,
            hint: hint,
            explanation: explanation,
            tags: tags,
            sourceReference: sourceReference
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw FlashcardAPIError.encodingError("Failed to encode flashcard data")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FlashcardAPIError.invalidResponse
            }

            if httpResponse.statusCode == 201 {
                let createResponse = try JSONDecoder().decode(CreateFlashcardResponse.self, from: data)
                print("✅ FlashcardAPIService: Flashcard created successfully")
                return createResponse.flashcard
            } else {
                let errorMessage = try? JSONDecoder().decode(BackendErrorResponse.self, from: data)
                throw FlashcardAPIError.serverError(errorMessage?.error ?? "Failed to create flashcard with status \(httpResponse.statusCode)")
            }
        } catch {
            if error is FlashcardAPIError {
                throw error
            }
            throw FlashcardAPIError.networkError("Network error: \(error.localizedDescription)")
        }
    }

    func getFlashcards(for deckId: String, includeInactive: Bool = false) async throws -> [BackendFlashcard] {
        guard let jwtToken = authService.getCurrentJWTToken() else {
            throw FlashcardAPIError.notAuthenticated
        }

        var urlComponents = URLComponents(string: "\(baseURL)/flashcards/deck/\(deckId)")
        urlComponents?.queryItems = [
            URLQueryItem(name: "include_inactive", value: includeInactive ? "true" : "false")
        ]

        guard let url = urlComponents?.url else {
            throw FlashcardAPIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FlashcardAPIError.invalidResponse
            }

            if httpResponse.statusCode == 200 {
                let getResponse = try JSONDecoder().decode(GetFlashcardsResponse.self, from: data)
                return getResponse.flashcards
            } else {
                let errorMessage = try? JSONDecoder().decode(BackendErrorResponse.self, from: data)
                throw FlashcardAPIError.serverError(errorMessage?.error ?? "Failed to get flashcards with status \(httpResponse.statusCode)")
            }
        } catch {
            if error is FlashcardAPIError {
                throw error
            }
            throw FlashcardAPIError.networkError("Network error: \(error.localizedDescription)")
        }
    }

    func updateFlashcard(
        id: String,
        front: String? = nil,
        back: String? = nil,
        hint: String? = nil,
        explanation: String? = nil,
        tags: [String]? = nil,
        isActive: Bool? = nil
    ) async throws -> BackendFlashcard {
        guard let jwtToken = authService.getCurrentJWTToken() else {
            throw FlashcardAPIError.notAuthenticated
        }

        guard let url = URL(string: "\(baseURL)/flashcards/\(id)") else {
            throw FlashcardAPIError.invalidURL
        }

        var requestData: [String: Any] = [:]
        if let front = front { requestData["front"] = front }
        if let back = back { requestData["back"] = back }
        if let hint = hint { requestData["hint"] = hint }
        if let explanation = explanation { requestData["explanation"] = explanation }
        if let tags = tags { requestData["tags"] = tags }
        if let isActive = isActive { requestData["is_active"] = isActive }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            throw FlashcardAPIError.encodingError("Failed to encode update data")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FlashcardAPIError.invalidResponse
            }

            if httpResponse.statusCode == 200 {
                let updateResponse = try JSONDecoder().decode(CreateFlashcardResponse.self, from: data)
                return updateResponse.flashcard
            } else {
                let errorMessage = try? JSONDecoder().decode(BackendErrorResponse.self, from: data)
                throw FlashcardAPIError.serverError(errorMessage?.error ?? "Failed to update flashcard with status \(httpResponse.statusCode)")
            }
        } catch {
            if error is FlashcardAPIError {
                throw error
            }
            throw FlashcardAPIError.networkError("Network error: \(error.localizedDescription)")
        }
    }

    func deleteFlashcard(id: String) async throws {
        guard let jwtToken = authService.getCurrentJWTToken() else {
            throw FlashcardAPIError.notAuthenticated
        }

        guard let url = URL(string: "\(baseURL)/flashcards/\(id)") else {
            throw FlashcardAPIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FlashcardAPIError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                let errorMessage = try? JSONDecoder().decode(BackendErrorResponse.self, from: data)
                throw FlashcardAPIError.serverError(errorMessage?.error ?? "Failed to delete flashcard with status \(httpResponse.statusCode)")
            }
        } catch {
            if error is FlashcardAPIError {
                throw error
            }
            throw FlashcardAPIError.networkError("Network error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Errors

enum FlashcardAPIError: Error, LocalizedError {
    case notAuthenticated
    case invalidURL
    case encodingError(String)
    case decodingError(String)
    case invalidResponse
    case serverError(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please sign in again."
        case .invalidURL:
            return "Invalid API URL"
        case .encodingError(let message):
            return "Encoding error: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// BackendErrorResponse is already defined in AuthenticationService