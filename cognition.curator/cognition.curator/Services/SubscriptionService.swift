import Foundation
import Combine
import StoreKit

@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published var isPremium = false
    @Published var subscriptionStatus: SubscriptionStatus = .free
    @Published var expirationDate: Date?
    @Published var isLoading = false

    enum SubscriptionStatus {
        case free
        case premium
        case premiumExpired
        case familySharing
    }

    enum PremiumFeature {
        case aiAnswerGeneration
        case offlineSync
        case advancedAnalytics
        case unlimitedDecks
        case customThemes
        case exportFeatures

        var displayName: String {
            switch self {
            case .aiAnswerGeneration:
                return "AI Answer Generation"
            case .offlineSync:
                return "Offline Sync"
            case .advancedAnalytics:
                return "Advanced Analytics"
            case .unlimitedDecks:
                return "Unlimited Decks"
            case .customThemes:
                return "Custom Themes"
            case .exportFeatures:
                return "Export Features"
            }
        }

        var description: String {
            switch self {
            case .aiAnswerGeneration:
                return "Generate intelligent answers for your questions using AI"
            case .offlineSync:
                return "Sync your progress and decks when offline"
            case .advancedAnalytics:
                return "Detailed learning analytics and insights"
            case .unlimitedDecks:
                return "Create unlimited flashcard decks"
            case .customThemes:
                return "Personalize your app with custom themes"
            case .exportFeatures:
                return "Export your decks and progress data"
            }
        }
    }

    private init() {
        loadSubscriptionStatus()
    }

    // MARK: - Feature Access

    func canAccess(_ feature: PremiumFeature) -> Bool {
        switch subscriptionStatus {
        case .premium, .familySharing:
            return true
        case .free, .premiumExpired:
            return false
        }
    }

    func requiresPremium(_ feature: PremiumFeature) -> Bool {
        return !canAccess(feature)
    }

    // MARK: - Subscription Management

    func loadSubscriptionStatus() {
        // For demo purposes, check UserDefaults
        // In production, this would check App Store receipts

        if let premiumEnd = UserDefaults.standard.object(forKey: "premium_expiration") as? Date {
            if premiumEnd > Date() {
                isPremium = true
                subscriptionStatus = .premium
                expirationDate = premiumEnd
            } else {
                isPremium = false
                subscriptionStatus = .premiumExpired
                expirationDate = premiumEnd
            }
        } else {
            // Demo: Grant premium for development
            #if DEBUG
            isPremium = true
            subscriptionStatus = .premium
            expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
            #else
            isPremium = false
            subscriptionStatus = .free
            expirationDate = nil
            #endif
        }

        print("📱 SubscriptionService: Status = \(subscriptionStatus), Premium = \(isPremium)")
    }

    func purchasePremium() async throws {
        isLoading = true
        defer { isLoading = false }

        // Simulate purchase process
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Grant premium access
        let expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        UserDefaults.standard.set(expirationDate, forKey: "premium_expiration")

        await MainActor.run {
            self.isPremium = true
            self.subscriptionStatus = .premium
            self.expirationDate = expirationDate
        }
    }

    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        // Simulate restore process
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Check for existing purchases (simplified)
        loadSubscriptionStatus()
    }

    // MARK: - Feature Gating Helpers

    func showPremiumRequired(for feature: PremiumFeature) -> PremiumRequiredInfo {
        return PremiumRequiredInfo(
            feature: feature,
            title: "\(feature.displayName) is Premium",
            message: "Upgrade to Premium to unlock \(feature.description.lowercased()).",
            ctaText: "Upgrade to Premium"
        )
    }

    // MARK: - Mock Premium Grants (Development)

    func grantDevelopmentPremium() {
        let expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        UserDefaults.standard.set(expirationDate, forKey: "premium_expiration")
        loadSubscriptionStatus()
    }

    func revokeDevelopmentPremium() {
        UserDefaults.standard.removeObject(forKey: "premium_expiration")
        loadSubscriptionStatus()
    }
}

// MARK: - Premium Required Info

struct PremiumRequiredInfo {
    let feature: SubscriptionService.PremiumFeature
    let title: String
    let message: String
    let ctaText: String
}