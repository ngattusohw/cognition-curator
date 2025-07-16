import Foundation
import SwiftUI
import CryptoKit
import AuthenticationServices
import ObjectiveC

// MARK: - Apple Sign In Delegate

private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private let completion: (Result<ASAuthorizationResult, Error>) -> Void
    
    init(completion: @escaping (Result<ASAuthorizationResult, Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        let result = ASAuthorizationResult(credential: authorization.credential, provider: authorization.provider)
        completion(.success(result))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

// MARK: - ASAuthorizationResult

private struct ASAuthorizationResult {
    let credential: ASAuthorizationCredential
    let provider: ASAuthorizationProvider
}

// MARK: - Authentication Service

class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var authState: AuthenticationState = .unauthenticated
    @Published var currentUser: UserAccount?
    
    private let userDefaultsKey = "currentUserId"
    private let usersStorageKey = "storedUsers"
    
    init() {
        loadSavedUser()
    }
    
    // MARK: - Public Methods
    
    func signUp(name: String, email: String, password: String) async {
        await MainActor.run {
            authState = .authenticating
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Validate input
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await setError(.unknown("Name cannot be empty"))
            return
        }
        
        guard isValidEmail(email) else {
            await setError(.invalidEmail)
            return
        }
        
        guard password.count >= 8 else {
            await setError(.weakPassword)
            return
        }
        
        // Check if user already exists
        if await userExists(email: email) {
            await setError(.emailAlreadyExists)
            return
        }
        
        // Create new user
        let newUser = UserAccount(
            id: UUID(),
            email: email.lowercased(),
            name: name,
            createdAt: Date(),
            isPremium: false,
            streakCount: 0,
            totalReviews: 0,
            appleId: nil
        )
        
        // Store user credentials (in production, this would be handled by a secure backend)
        await storeUser(user: newUser, password: password)
        
        await MainActor.run {
            currentUser = newUser
            authState = .authenticated(newUser)
            saveCurrentUser(newUser)
        }
    }
    
    func signIn(email: String, password: String) async {
        await MainActor.run {
            authState = .authenticating
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        guard let storedUser = await getStoredUser(email: email.lowercased()) else {
            await setError(.userNotFound)
            return
        }
        
        guard await verifyPassword(password, for: email.lowercased()) else {
            await setError(.wrongPassword)
            return
        }
        
        await MainActor.run {
            currentUser = storedUser
            authState = .authenticated(storedUser)
            saveCurrentUser(storedUser)
        }
    }
    
    func signOut() {
        withAnimation(.easeInOut(duration: 0.5)) {
            authState = .unauthenticated
            currentUser = nil
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        }
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple() async {
        await MainActor.run {
            authState = .authenticating
        }
        
        // Check if we're running on simulator
        #if targetEnvironment(simulator)
        // Apple Sign In doesn't work reliably on simulator, provide a demo account
        await createSimulatorAppleUser()
        #else
        // Real device Apple Sign In implementation
        do {
            let result = try await performAppleSignIn()
            
            guard let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential else {
                await setError(.unknown("Invalid Apple ID credential"))
                return
            }
            
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            // For first-time sign in, Apple provides email and name
            // For subsequent sign ins, they might be nil, so we'll use stored data
            let displayName = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            // Check if user already exists (by Apple ID)
            if let existingUser = await getStoredAppleUser(appleId: userIdentifier) {
                // Existing user - sign them in
                await MainActor.run {
                    currentUser = existingUser
                    authState = .authenticated(existingUser)
                    saveCurrentUser(existingUser)
                }
            } else {
                // New user - create account
                let newUser = UserAccount(
                    id: UUID(),
                    email: email ?? "user@privaterelay.appleid.com", // Apple private relay fallback
                    name: displayName.isEmpty ? "Apple User" : displayName,
                    createdAt: Date(),
                    isPremium: false,
                    streakCount: 0,
                    totalReviews: 0,
                    appleId: userIdentifier
                )
                
                await storeAppleUser(user: newUser)
                
                await MainActor.run {
                    currentUser = newUser
                    authState = .authenticated(newUser)
                    saveCurrentUser(newUser)
                }
            }
            
        } catch {
            let errorMessage: String
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    errorMessage = "Apple Sign In was canceled"
                case .failed:
                    errorMessage = "Apple Sign In failed. Please try again."
                case .invalidResponse:
                    errorMessage = "Invalid response from Apple Sign In"
                case .notHandled:
                    errorMessage = "Apple Sign In is not available"
                case .unknown:
                    errorMessage = "Apple Sign In encountered an unknown error"
                case .notInteractive:
                    errorMessage = "Apple Sign In requires user interaction"
                case .matchedExcludedCredential:
                    errorMessage = "Apple Sign In credential is excluded"
                case .credentialImport:
                    errorMessage = "Apple Sign In credential import failed"
                case .credentialExport:
                    errorMessage = "Apple Sign In credential export failed"
                @unknown default:
                    errorMessage = "Apple Sign In failed with error: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
            }
            await setError(.unknown(errorMessage))
        }
        #endif
    }
    
    private func createSimulatorAppleUser() async {
        // Create a demo Apple user for simulator testing
        let demoUser = UserAccount(
            id: UUID(),
            email: "apple.demo@privaterelay.appleid.com",
            name: "Apple Demo User",
            createdAt: Date(),
            isPremium: false,
            streakCount: 3,
            totalReviews: 25,
            appleId: "simulator_apple_user"
        )
        
        await storeAppleUser(user: demoUser)
        
        await MainActor.run {
            currentUser = demoUser
            authState = .authenticated(demoUser)
            saveCurrentUser(demoUser)
        }
    }
    
    @MainActor
    private func performAppleSignIn() async throws -> ASAuthorizationResult {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = AppleSignInDelegate { result in
                switch result {
                case .success(let authResult):
                    continuation.resume(returning: authResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            
            // Store delegate in the controller to keep it alive
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            controller.performRequests()
        }
    }
    
    func deleteAccount() async {
        guard let user = currentUser else { return }
        
        await MainActor.run {
            authState = .authenticating
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Remove user data
        await removeStoredUser(userId: user.id)
        
        await MainActor.run {
            authState = .unauthenticated
            currentUser = nil
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        }
    }
    
    var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }
    
    // MARK: - Private Methods
    
    private func setError(_ error: AuthError) async {
        await MainActor.run {
            authState = .error(error)
        }
        
        // Auto-clear error after 3 seconds
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        await MainActor.run {
            if case .error = authState {
                authState = .unauthenticated
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Storage Methods (Mock implementation)
    
    private func storeUser(user: UserAccount, password: String) async {
        var storedUsers = getStoredUsers()
        let hashedPassword = hashPassword(password)
        
        let userDict: [String: Any] = [
            "id": user.id.uuidString,
            "email": user.email,
            "name": user.name,
            "createdAt": user.createdAt.timeIntervalSince1970,
            "isPremium": user.isPremium,
            "streakCount": user.streakCount,
            "totalReviews": user.totalReviews,
            "passwordHash": hashedPassword
        ]
        
        storedUsers[user.email] = userDict
        UserDefaults.standard.set(storedUsers, forKey: usersStorageKey)
    }
    
    private func getStoredUser(email: String) async -> UserAccount? {
        let storedUsers = getStoredUsers()
        
        guard let userDict = storedUsers[email] as? [String: Any],
              let idString = userDict["id"] as? String,
              let id = UUID(uuidString: idString),
              let userEmail = userDict["email"] as? String,
              let name = userDict["name"] as? String,
              let createdAtInterval = userDict["createdAt"] as? TimeInterval,
              let isPremium = userDict["isPremium"] as? Bool,
              let streakCount = userDict["streakCount"] as? Int,
              let totalReviews = userDict["totalReviews"] as? Int else {
            return nil
        }
        
        return UserAccount(
            id: id,
            email: userEmail,
            name: name,
            createdAt: Date(timeIntervalSince1970: createdAtInterval),
            isPremium: isPremium,
            streakCount: streakCount,
            totalReviews: totalReviews,
            appleId: userDict["appleId"] as? String
        )
    }
    
    private func userExists(email: String) async -> Bool {
        let storedUsers = getStoredUsers()
        return storedUsers[email] != nil
    }
    
    private func verifyPassword(_ password: String, for email: String) async -> Bool {
        let storedUsers = getStoredUsers()
        
        guard let userDict = storedUsers[email] as? [String: Any],
              let storedHash = userDict["passwordHash"] as? String else {
            return false
        }
        
        let inputHash = hashPassword(password)
        return inputHash == storedHash
    }
    
    private func removeStoredUser(userId: UUID) async {
        var storedUsers = getStoredUsers()
        
        // Find and remove user by ID
        for (email, userDict) in storedUsers {
            if let dict = userDict as? [String: Any],
               let idString = dict["id"] as? String,
               idString == userId.uuidString {
                storedUsers.removeValue(forKey: email)
                break
            }
        }
        
        UserDefaults.standard.set(storedUsers, forKey: usersStorageKey)
    }
    
    private func getStoredUsers() -> [String: Any] {
        return UserDefaults.standard.dictionary(forKey: usersStorageKey) ?? [:]
    }
    
    private func saveCurrentUser(_ user: UserAccount) {
        UserDefaults.standard.set(user.id.uuidString, forKey: userDefaultsKey)
    }
    
    private func loadSavedUser() {
        guard let userIdString = UserDefaults.standard.string(forKey: userDefaultsKey),
              let userId = UUID(uuidString: userIdString) else {
            authState = .unauthenticated
            return
        }
        
        Task {
            // Find user by ID
            let storedUsers = getStoredUsers()
            for (_, userDict) in storedUsers {
                if let dict = userDict as? [String: Any],
                   let idString = dict["id"] as? String,
                   idString == userId.uuidString,
                   let email = dict["email"] as? String {
                    
                    if let user = await getStoredUser(email: email) {
                        await MainActor.run {
                            currentUser = user
                            authState = .authenticated(user)
                        }
                        return
                    }
                }
            }
            
            // User not found, sign out
            await MainActor.run {
                authState = .unauthenticated
                UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            }
        }
    }
    
    // MARK: - Apple ID Storage Methods
    
    private func storeAppleUser(user: UserAccount) async {
        var storedUsers = getStoredUsers()
        
        let userDict: [String: Any] = [
            "id": user.id.uuidString,
            "email": user.email,
            "name": user.name,
            "createdAt": user.createdAt.timeIntervalSince1970,
            "isPremium": user.isPremium,
            "streakCount": user.streakCount,
            "totalReviews": user.totalReviews,
            "appleId": user.appleId ?? ""
        ]
        
        // Store by Apple ID instead of email for Apple users
        if let appleId = user.appleId {
            storedUsers["apple_\(appleId)"] = userDict
        }
        
        UserDefaults.standard.set(storedUsers, forKey: usersStorageKey)
    }
    
    private func getStoredAppleUser(appleId: String) async -> UserAccount? {
        let storedUsers = getStoredUsers()
        let key = "apple_\(appleId)"
        
        guard let userDict = storedUsers[key] as? [String: Any],
              let idString = userDict["id"] as? String,
              let id = UUID(uuidString: idString),
              let email = userDict["email"] as? String,
              let name = userDict["name"] as? String,
              let createdAtInterval = userDict["createdAt"] as? TimeInterval,
              let isPremium = userDict["isPremium"] as? Bool,
              let streakCount = userDict["streakCount"] as? Int,
              let totalReviews = userDict["totalReviews"] as? Int,
              let storedAppleId = userDict["appleId"] as? String else {
            return nil
        }
        
        return UserAccount(
            id: id,
            email: email,
            name: name,
            createdAt: Date(timeIntervalSince1970: createdAtInterval),
            isPremium: isPremium,
            streakCount: streakCount,
            totalReviews: totalReviews,
            appleId: storedAppleId
        )
    }
    
    // MARK: - User Profile Updates
    
    func updateUserProfile(name: String? = nil, isPremium: Bool? = nil) async {
        guard let currentUser = currentUser else { return }
        
        let updatedUser = UserAccount(
            id: currentUser.id,
            email: currentUser.email,
            name: name ?? currentUser.name,
            createdAt: currentUser.createdAt,
            isPremium: isPremium ?? currentUser.isPremium,
            streakCount: currentUser.streakCount,
            totalReviews: currentUser.totalReviews,
            appleId: currentUser.appleId
        )
        
        // Update stored user data
        var storedUsers = getStoredUsers()
        if var userDict = storedUsers[currentUser.email] as? [String: Any] {
            userDict["name"] = updatedUser.name
            userDict["isPremium"] = updatedUser.isPremium
            storedUsers[currentUser.email] = userDict
            UserDefaults.standard.set(storedUsers, forKey: usersStorageKey)
        }
        
        await MainActor.run {
            self.currentUser = updatedUser
            authState = .authenticated(updatedUser)
        }
    }
    
    func updateUserStats(streakCount: Int? = nil, totalReviews: Int? = nil) async {
        guard let currentUser = currentUser else { return }
        
        let updatedUser = UserAccount(
            id: currentUser.id,
            email: currentUser.email,
            name: currentUser.name,
            createdAt: currentUser.createdAt,
            isPremium: currentUser.isPremium,
            streakCount: streakCount ?? currentUser.streakCount,
            totalReviews: totalReviews ?? currentUser.totalReviews,
            appleId: currentUser.appleId
        )
        
        // Update stored user data
        var storedUsers = getStoredUsers()
        if var userDict = storedUsers[currentUser.email] as? [String: Any] {
            userDict["streakCount"] = updatedUser.streakCount
            userDict["totalReviews"] = updatedUser.totalReviews
            storedUsers[currentUser.email] = userDict
            UserDefaults.standard.set(storedUsers, forKey: usersStorageKey)
        }
        
        await MainActor.run {
            self.currentUser = updatedUser
            authState = .authenticated(updatedUser)
        }
    }
} 