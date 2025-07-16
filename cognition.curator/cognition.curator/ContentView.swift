//
//  ContentView.swift
//  cognition.curator
//
//  Created by Nicholas Gattuso on 7/13/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var forceReview = false
    @EnvironmentObject var deepLinkHandler: DeepLinkHandler
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab, forceReview: $forceReview)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            DecksView()
                .tabItem {
                    Image(systemName: "rectangle.stack.fill")
                    Text("Decks")
                }
                .tag(1)
            
            ReviewView(forceReview: $forceReview, selectedTab: $selectedTab)
                .environmentObject(deepLinkHandler)
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Review")
                }
                .tag(2)
            
            ProgressStatsView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .onChange(of: deepLinkHandler.selectedTab) { newTab in
            selectedTab = newTab
        }
        .onChange(of: deepLinkHandler.shouldOpenReview) { shouldOpen in
            if shouldOpen {
                forceReview = true
                deepLinkHandler.clearDeepLink()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
