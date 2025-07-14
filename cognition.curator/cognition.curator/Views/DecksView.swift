import SwiftUI
import CoreData

struct DecksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Deck.createdAt, ascending: false)],
        animation: .default)
    private var decks: FetchedResults<Deck>
    
    @State private var showingCreateDeck = false
    @State private var searchText = ""
    @State private var selectedFilter: DeckFilter = .all
    
    var filteredDecks: [Deck] {
        let filtered = decks.filter { deck in
            if !searchText.isEmpty {
                return deck.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
            return true
        }
        
        switch selectedFilter {
        case .all:
            return filtered
        case .superset:
            return filtered.filter { $0.isSuperset }
        case .premium:
            return filtered.filter { $0.isPremium }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter bar
                searchAndFilterBar
                
                if decks.isEmpty {
                    emptyStateView
                } else {
                    decksList
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Decks")
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
        }
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search decks...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DeckFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.displayName,
                            isSelected: selectedFilter == filter
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "rectangle.stack")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("No decks yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Create your first deck to start learning with spaced repetition")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: { showingCreateDeck = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Your First Deck")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer()
        }
    }
    
    private var decksList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredDecks, id: \.id) { deck in
                    NavigationLink(destination: DeckDetailView(deck: deck)) {
                        DeckCardView(deck: deck)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
}

struct DeckCardView: View {
    let deck: Deck
    @State private var cardCount = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(deck.name ?? "Untitled Deck")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(cardCount) cards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Premium badge
                if deck.isPremium {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .padding(6)
                        .background(Color.yellow.opacity(0.2))
                        .clipShape(Circle())
                }
                
                // Superset badge
                if deck.isSuperset {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(6)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            
            // Progress bar
            ProgressView(value: 0.7) // TODO: Calculate actual progress
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            // Footer
            HStack {
                Text("Last studied: \(formatDate(deck.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    // Start review
                }) {
                    Text("Review")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onAppear {
            cardCount = deck.flashcards?.count ?? 0
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(uiColor: .systemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

enum DeckFilter: CaseIterable {
    case all, superset, premium
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .superset: return "Supersets"
        case .premium: return "Premium"
        }
    }
}

#Preview {
    DecksView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
