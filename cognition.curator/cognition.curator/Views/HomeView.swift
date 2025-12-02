import SwiftUI
import UIKit
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authService: AuthenticationService
    @Query(sort: \Deck.createdAt, order: .reverse) private var decks: [Deck]

    @Binding var selectedTab: Int
    @Binding var forceReview: Bool
    @StateObject private var progressDataService = ProgressDataService.shared

    @State private var showingCreateDeck = false
    @State private var showingProfile = false
    @State private var showingDeckSelector = false
    @State private var cardsDueToday = 0

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

                    // Profile quick access
                    profileQuickAccessSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(uiColor: UIColor.systemGroupedBackground))
            .navigationTitle("Cognition Curator")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingProfile = true }) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }

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
            .sheet(isPresented: $showingProfile) {
                ProfileView()
                    .environmentObject(authService)
            }
            .onAppear {
                loadStats()
                progressDataService.loadProgressData()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Clean, calm header
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.1), .purple.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.blue)

                        Text("Welcome back!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("Ready to strengthen your memory?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                )
                .background(Color(uiColor: UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Overview")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                StatCard(
                    title: "Cards Due",
                    value: "\(progressDataService.progressData?.cardsDueToday ?? cardsDueToday)",
                    icon: "clock.fill",
                    color: cardsDueToday > 0 ? .orange : .green
                )

                StatCard(
                    title: "Streak",
                    value: streakDisplayText,
                    icon: "flame.fill",
                    color: (progressDataService.progressData?.currentStreak ?? 0) > 0 ? .red : .gray
                )

                StatCard(
                    title: "Decks",
                    value: "\(decks.count)",
                    icon: "rectangle.stack.fill",
                    color: .blue
                )
            }
        }
    }

    private var streakDisplayText: String {
        let streak = progressDataService.progressData?.currentStreak ?? 0
        return streak > 0 ? "\(streak) days" : "Start today"
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

                let totalCardsDue = progressDataService.progressData?.cardsDueToday ?? cardsDueToday
                if totalCardsDue > 0 {
                    Text("\(totalCardsDue)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
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
                        NavigationLink(destination: DeckDetailView(deck: deck)) {
                            DeckRowView(deck: deck)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    private var profileQuickAccessSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Access")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: { showingProfile = true }) {
                    HStack(spacing: 4) {
                        Text("Profile")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

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
                    title: "Profile",
                    icon: "person.crop.circle.fill",
                    color: .purple
                ) {
                    showingProfile = true
                }
            }
        }
    }

    private func loadStats() {
        let stats = SpacedRepetitionService.shared.getTodayReviewStats(context: modelContext)
        cardsDueToday = stats.dueCards + stats.newCards + stats.learningCards
        // Real streak data now comes from progressDataService
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
        .modelContainer(PersistenceController.preview)
}
