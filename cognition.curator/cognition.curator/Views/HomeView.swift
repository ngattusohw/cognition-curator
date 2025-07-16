import SwiftUI
import UIKit
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Deck.createdAt, ascending: false)],
        animation: .default)
    private var decks: FetchedResults<Deck>
    
    @Binding var selectedTab: Int
    @Binding var forceReview: Bool
    
    @State private var showingCreateDeck = false
    @State private var showingSettings = false
    @State private var showingDeckSelector = false
    @State private var cardsDueToday = 0
    @State private var currentStreak = 0
    @State private var animateGradient = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with gradient background
                    headerSection
                    
                    // Quick stats
                    statsSection
                    
                    // Daily review card
                    dailyReviewCard
                    
                    // Recent decks
                    recentDecksSection
                    
                    // Quick actions
                    quickActionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(uiColor: UIColor.systemGroupedBackground))
            .navigationTitle("Cognition Curator")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateDeck = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingCreateDeck) {
                CreateDeckView()
            }
            .sheet(isPresented: $showingDeckSelector) {
                DeckSelectorView { deckIds, mode in
                    startDeckReview(deckIds: deckIds, mode: mode)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                loadStats()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Animated gradient background
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.8), .purple.opacity(0.6)],
                        startPoint: animateGradient ? .topLeading : .bottomTrailing,
                        endPoint: animateGradient ? .bottomTrailing : .topLeading
                    )
                )
                .frame(height: 120)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("Welcome back!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Ready to strengthen your memory?")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                )
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Cards Due",
                value: "\(cardsDueToday)",
                icon: "clock.fill",
                color: .orange
            )
            
            StatCard(
                title: "Streak",
                value: "\(currentStreak) days",
                icon: "flame.fill",
                color: .red
            )
            
            StatCard(
                title: "Decks",
                value: "\(decks.count)",
                icon: "rectangle.stack.fill",
                color: .blue
            )
        }
    }
    
    private var dailyReviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Daily Review")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if cardsDueToday > 0 {
                    Text("\(cardsDueToday) cards")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                }
            }
            
            if cardsDueToday > 0 {
                Text("You have \(cardsDueToday) cards ready for review. Take 5 minutes to strengthen your memory!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    // Navigate to review
                    forceReview = false
                    selectedTab = 2
                }) {
                    HStack {
                        Text("Start Review")
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Text("Great job! All caught up with your reviews.")
                    .font(.subheadline)
                    .foregroundColor(.green)
                
                VStack(spacing: 12) {
                    Button(action: {
                        // Navigate to review anyway
                        forceReview = true
                        selectedTab = 2
                    }) {
                        HStack {
                            Text("Review Anyway")
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.clockwise")
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: {
                        showingDeckSelector = true
                    }) {
                        HStack {
                            Text("Select Decks to Review")
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Image(systemName: "rectangle.stack")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var recentDecksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Decks")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                NavigationLink("See All", destination: DecksView())
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            if decks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No decks yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Create your first deck to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(decks.prefix(3)), id: \.id) { deck in
                        DeckRowView(deck: deck)
                    }
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title3)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                QuickActionButton(
                    title: "Create Deck",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    showingCreateDeck = true
                }
                
                QuickActionButton(
                    title: "Select Decks",
                    icon: "rectangle.stack.fill",
                    color: .green
                ) {
                    showingDeckSelector = true
                }
                
                QuickActionButton(
                    title: "Settings",
                    icon: "gear.fill",
                    color: .gray
                ) {
                    showingSettings = true
                }
            }
        }
    }
    
    private func loadStats() {
        let stats = SpacedRepetitionService.shared.getTodayReviewStats(context: viewContext)
        cardsDueToday = stats.dueCards + stats.newCards + stats.learningCards
        // TODO: Load streak from UserDefaults or Core Data
        currentStreak = 5 // Mock data
    }
    
    private func startDeckReview(deckIds: [UUID], mode: ReviewMode) {
        // Store the deck review configuration
        UserDefaults.standard.set(deckIds.map { $0.uuidString }, forKey: "pendingDeckReview")
        UserDefaults.standard.set(mode.rawValue, forKey: "pendingReviewMode")
        
        // Navigate to review tab
        selectedTab = 2
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(uiColor: UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(0), forceReview: .constant(false))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
