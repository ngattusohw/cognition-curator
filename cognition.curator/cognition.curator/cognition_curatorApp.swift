//
//  cognition_curatorApp.swift
//  cognition.curator
//
//  Created by Nicholas Gattuso on 7/13/25.
//

import SwiftUI

@main
struct cognition_curatorApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var onboardingState = OnboardingState()
    @StateObject private var deepLinkHandler = DeepLinkHandler()

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated && onboardingState.isOnboardingComplete {
                    // Main app content
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(authService)
                        .environmentObject(deepLinkHandler)
                } else {
                    // Onboarding and authentication flow
                    OnboardingView()
                        .environmentObject(authService)
                        .environmentObject(onboardingState)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: authService.isAuthenticated)
            .animation(.easeInOut(duration: 0.5), value: onboardingState.isOnboardingComplete)
            .onOpenURL { url in
                if authService.isAuthenticated && onboardingState.isOnboardingComplete {
                    deepLinkHandler.handle(url: url)
                }
            }
        }
    }
}
