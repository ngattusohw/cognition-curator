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
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
