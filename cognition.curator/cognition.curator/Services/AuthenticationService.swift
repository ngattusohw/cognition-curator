import Foundation
import SwiftUI
import CryptoKit

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
            totalReviews: 0
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
            totalReviews: totalReviews
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
            totalReviews: currentUser.totalReviews
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
            totalReviews: totalReviews ?? currentUser.totalReviews
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