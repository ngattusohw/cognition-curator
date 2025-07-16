import Foundation
import SwiftUI

// MARK: - Onboarding Models

struct OnboardingPage {
    let id: Int
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let primaryColor: Color
    let secondaryColor: Color
}

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case spacedRepetition = 1
    case deckManagement = 2
    case progress = 3
    case authentication = 4
    
    var page: OnboardingPage {
        switch self {
        case .welcome:
            return OnboardingPage(
                id: 0,
                title: "Welcome to\nCognition Curator",
                subtitle: "Master anything with science-backed learning",
                description: "Transform your learning with spaced repetition algorithms proven to boost memory retention by up to 200%.",
                imageName: "brain.head.profile",
                primaryColor: .blue,
                secondaryColor: .cyan
            )
        case .spacedRepetition:
            return OnboardingPage(
                id: 1,
                title: "Smart Review\nScheduling",
                subtitle: "Never forget what you learn",
                description: "Our advanced algorithm schedules reviews at the perfect moment, right before you're about to forget.",
                imageName: "clock.arrow.circlepath",
                primaryColor: .green,
                secondaryColor: .mint
            )
        case .deckManagement:
            return OnboardingPage(
                id: 2,
                title: "Organize Your\nKnowledge",
                subtitle: "Create decks for any subject",
                description: "Build flashcard decks for languages, medical terms, programming concepts, or anything you want to master.",
                imageName: "rectangle.stack.fill",
                primaryColor: .orange,
                secondaryColor: .yellow
            )
        case .progress:
            return OnboardingPage(
                id: 3,
                title: "Track Your\nProgress",
                subtitle: "Watch your knowledge grow",
                description: "Detailed analytics show your learning streaks, accuracy rates, and mastery levels across all subjects.",
                imageName: "chart.line.uptrend.xyaxis",
                primaryColor: .purple,
                secondaryColor: .pink
            )
        case .authentication:
            return OnboardingPage(
                id: 4,
                title: "Ready to Start\nLearning?",
                subtitle: "Create your account to begin",
                description: "Join thousands of learners who've already transformed their study habits with Cognition Curator.",
                imageName: "person.crop.circle.badge.plus",
                primaryColor: .indigo,
                secondaryColor: .blue
            )
        }
    }
}

// MARK: - Authentication Models

struct UserAccount: Equatable {
    let id: UUID
    let email: String
    let name: String
    let createdAt: Date
    let isPremium: Bool
    let streakCount: Int
    let totalReviews: Int
}

enum AuthenticationState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(UserAccount)
    case error(AuthError)
    
    static func == (lhs: AuthenticationState, rhs: AuthenticationState) -> Bool {
        switch (lhs, rhs) {
        case (.unauthenticated, .unauthenticated):
            return true
        case (.authenticating, .authenticating):
            return true
        case (.authenticated(let lhsUser), .authenticated(let rhsUser)):
            return lhsUser.id == rhsUser.id
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case weakPassword
    case emailAlreadyExists
    case userNotFound
    case wrongPassword
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 8 characters long"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .userNotFound:
            return "No account found with this email"
        case .wrongPassword:
            return "Incorrect password"
        case .networkError:
            return "Network error. Please check your connection"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Form Validation

struct SignUpForm {
    var name: String = ""
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    
    var isValidName: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count >= 2
    }
    
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    var isValidPassword: Bool {
        password.count >= 8
    }
    
    var passwordsMatch: Bool {
        password == confirmPassword && !password.isEmpty
    }
    
    var isValid: Bool {
        isValidName && isValidEmail && isValidPassword && passwordsMatch
    }
}

struct SignInForm {
    var email: String = ""
    var password: String = ""
    
    var isValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
}

// MARK: - Onboarding State

class OnboardingState: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var isOnboardingComplete: Bool = false
    @Published var showingAuthentication: Bool = false
    
    private let userDefaultsKey = "hasCompletedOnboarding"
    
    init() {
        // Check if user has completed onboarding before
        isOnboardingComplete = UserDefaults.standard.bool(forKey: userDefaultsKey)
    }
    
    func nextStep() {
        if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentStep = nextStep
            }
            
            if nextStep == .authentication {
                showingAuthentication = true
            }
        }
    }
    
    func previousStep() {
        if let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentStep = previousStep
            }
            
            if currentStep != .authentication {
                showingAuthentication = false
            }
        }
    }
    
    func skipToAuthentication() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentStep = .authentication
            showingAuthentication = true
        }
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
        withAnimation(.easeInOut(duration: 0.5)) {
            isOnboardingComplete = true
        }
    }
    
    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: userDefaultsKey)
        withAnimation(.easeInOut(duration: 0.5)) {
            currentStep = .welcome
            isOnboardingComplete = false
            showingAuthentication = false
        }
    }
} 