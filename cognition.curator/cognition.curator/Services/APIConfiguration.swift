import Foundation

/**
 * Centralized API Configuration for Cognition Curator
 *
 * This configuration automatically switches between development and production
 * environments based on the build configuration.
 */
struct APIConfiguration {

    // MARK: - Base URL Configuration

    #if DEBUG
    /// Development environment - connects to local Flask server
    static let baseURL = "http://127.0.0.1:5001/api"
    static let environment = "development"
    #else
    /// Production environment - connects to Railway deployment
    static let baseURL = "https://cognition-curator-production.up.railway.app/api"
    static let environment = "production"
    #endif

    // MARK: - Endpoint Paths

    struct Auth {
        static let profile = "/auth/profile"
        static let appleSignIn = "/auth/apple-signin"
        static let refresh = "/auth/refresh"
    }

    struct Decks {
        static let list = "/decks/"
        static let create = "/decks/"
        static func detail(_ id: String) -> String { "/decks/\(id)" }
    }

    struct Flashcards {
        static let create = "/flashcards/"
        static let batch = "/flashcards/batch"
        static func byDeck(_ deckId: String) -> String { "/flashcards/deck/\(deckId)" }
        static func detail(_ id: String) -> String { "/flashcards/\(id)" }
    }

    struct Analytics {
        static func dashboard(days: Int = 30) -> String { "/analytics/dashboard?days=\(days)" }
        static let syncStudySession = "/sync/study-session"
        static let syncFlashcardReview = "/sync/flashcard-review"
        static let syncUserStats = "/sync/user-stats"
    }

    struct AI {
        static let generateFlashcards = "/ai/generate-flashcards"
        static let generateAnswer = "/ai/generate-answer"
    }

    // MARK: - Helper Methods

    /// Get full URL for an endpoint path
    static func url(for path: String) -> String {
        return baseURL + path
    }

    /// Get URL object for an endpoint path
    static func urlObject(for path: String) -> URL? {
        return URL(string: url(for: path))
    }

    // MARK: - Configuration Info

    /// Print current configuration (useful for debugging)
    static func printConfiguration() {
        print("🔧 APIConfiguration: Environment = \(environment)")
        print("🔧 APIConfiguration: Base URL = \(baseURL)")
    }
}
