import Foundation

// MARK: - Backend Models

struct BackendDeck: Codable {
    let id: String
    let name: String
    let description: String?
    let category: String?
    let color: String
    let icon: String?
    let userId: String
    let isActive: Bool
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, description, category, color, icon
        case userId = "user_id"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CreateDeckRequest: Codable {
    let name: String
    let description: String?
    let category: String?
    let color: String
    let icon: String?
}

struct CreateDeckResponse: Codable {
    let deck: BackendDeck
}

struct GetDecksResponse: Codable {
    let decks: [BackendDeck]
}

// MARK: - DeckAPIService

@MainActor
class DeckAPIService: ObservableObject {
    private let baseURL = "http://127.0.0.1:5001/api"
    private let authService: AuthenticationService

    init(authService: AuthenticationService) {
        self.authService = authService
    }

    // MARK: - API Methods

    func createDeck(name: String, description: String? = nil, category: String? = nil, color: String = "#007AFF", icon: String? = nil) async throws -> BackendDeck {
        guard let jwtToken = authService.getCurrentJWTToken() else {
            print("❌ DeckAPIService: No JWT token found")
            throw DeckAPIError.notAuthenticated
        }

        print("✅ DeckAPIService: Using JWT token: \(String(jwtToken.prefix(20)))...")

        guard let url = URL(string: "\(baseURL)/decks/") else {
            throw DeckAPIError.invalidURL
        }

        let request = CreateDeckRequest(
            name: name,
            description: description,
            category: category,
            color: color,
            icon: icon
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw DeckAPIError.encodingError("Failed to encode deck data")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw DeckAPIError.invalidResponse
            }

            if httpResponse.statusCode == 201 {
                let createResponse = try JSONDecoder().decode(CreateDeckResponse.self, from: data)
                return createResponse.deck
            } else {
                let errorMessage = try? JSONDecoder().decode(BackendErrorResponse.self, from: data)
                throw DeckAPIError.serverError(errorMessage?.error ?? "Failed to create deck with status \(httpResponse.statusCode)")
            }
        } catch {
            if error is DeckAPIError {
                throw error
            }
            throw DeckAPIError.networkError("Network error: \(error.localizedDescription)")
        }
    }

    func getDecks() async throws -> [BackendDeck] {
        guard let jwtToken = authService.getCurrentJWTToken() else {
            throw DeckAPIError.notAuthenticated
        }

        guard let url = URL(string: "\(baseURL)/decks/") else {
            throw DeckAPIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw DeckAPIError.invalidResponse
            }

            if httpResponse.statusCode == 200 {
                let getResponse = try JSONDecoder().decode(GetDecksResponse.self, from: data)
                return getResponse.decks
            } else {
                let errorMessage = try? JSONDecoder().decode(BackendErrorResponse.self, from: data)
                throw DeckAPIError.serverError(errorMessage?.error ?? "Failed to get decks with status \(httpResponse.statusCode)")
            }
        } catch {
            if error is DeckAPIError {
                throw error
            }
            throw DeckAPIError.networkError("Network error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Errors

enum DeckAPIError: Error, LocalizedError {
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
