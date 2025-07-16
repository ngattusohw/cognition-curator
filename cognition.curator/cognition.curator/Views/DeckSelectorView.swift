import SwiftUI
import CoreData

struct DeckSelectorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Deck.createdAt, ascending: false)],
        animation: .default)
    private var decks: FetchedResults<Deck>
    
    @State private var selectedDeckIds: Set<UUID> = []
    @State private var selectedMode: ReviewMode = .normal
    @State private var showingReview = false
    @State private var deckStats: [UUID: (total: Int, new: Int, due: Int, learning: Int)] = [:]
    
    let onStartReview: ([UUID], ReviewMode) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Mode selector
                modeSelector
                
                // Deck list
                deckList
                
                // Summary and start button
                bottomSection
            }
            .navigationTitle("Select Decks to Review")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadDeckStats()
            }
        }
    }
    
    private var modeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review Mode")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                ForEach(ReviewMode.allCases, id: \.self) { mode in
                    ModeButton(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        action: { selectedMode = mode }
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color(uiColor: UIColor.systemBackground))
    }
    
    private var deckList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(decks, id: \.id) { deck in
                    DeckSelectionRow(
                        deck: deck,
                        isSelected: selectedDeckIds.contains(deck.id ?? UUID()),
                        stats: deckStats[deck.id ?? UUID()],
                        mode: selectedMode,
                        onToggle: { toggleDeck(deck) }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Color(uiColor: UIColor.systemGroupedBackground))
        .onChange(of: selectedMode) { _ in
            loadDeckStats()
        }
    }
    
    private var bottomSection: some View {
        VStack(spacing: 16) {
            if !selectedDeckIds.isEmpty {
                // Selected decks summary
                summarySection
            }
            
            // Start review button
            Button(action: startReview) {
                HStack {
                    Image(systemName: "play.fill")
                    Text(selectedDeckIds.isEmpty ? "Select Decks to Start" : "Start Review")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedDeckIds.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedDeckIds.isEmpty)
        }
        .padding(20)
        .background(Color(uiColor: UIColor.systemBackground))
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Selected: \(selectedDeckIds.count) deck\(selectedDeckIds.count == 1 ? "" : "s")")
                    .font(.headline)
                Spacer()
                Text(selectedMode.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(selectedMode.isPremium ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                    .foregroundColor(selectedMode.isPremium ? .orange : .blue)
                    .clipShape(Capsule())
            }
            
            let totalStats = calculateTotalStats()
            HStack(spacing: 20) {
                StatPill(title: "Total", value: "\(totalStats.total)", color: .gray)
                StatPill(title: "New", value: "\(totalStats.new)", color: .blue)
                StatPill(title: "Due", value: "\(totalStats.due)", color: .orange)
                StatPill(title: "Learning", value: "\(totalStats.learning)", color: .green)
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func toggleDeck(_ deck: Deck) {
        guard let deckId = deck.id else { return }
        
        if selectedDeckIds.contains(deckId) {
            selectedDeckIds.remove(deckId)
        } else {
            selectedDeckIds.insert(deckId)
        }
    }
    
    private func loadDeckStats() {
        for deck in decks {
            guard let deckId = deck.id else { continue }
            let stats = SpacedRepetitionService.shared.getDeckReviewStats(
                context: viewContext,
                deckIds: [deckId]
            )
            deckStats[deckId] = stats
        }
    }
    
    private func calculateTotalStats() -> (total: Int, new: Int, due: Int, learning: Int) {
        let stats = SpacedRepetitionService.shared.getDeckReviewStats(
            context: viewContext,
            deckIds: Array(selectedDeckIds)
        )
        return stats
    }
    
    private func startReview() {
        guard !selectedDeckIds.isEmpty else { return }
        onStartReview(Array(selectedDeckIds), selectedMode)
        dismiss()
    }
}

// MARK: - Supporting Views

struct ModeButton: View {
    let mode: ReviewMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mode.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                if mode.isPremium {
                    Text("Premium")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(uiColor: UIColor.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct DeckSelectionRow: View {
    let deck: Deck
    let isSelected: Bool
    let stats: (total: Int, new: Int, due: Int, learning: Int)?
    let mode: ReviewMode
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
                
                // Deck info
                VStack(alignment: .leading, spacing: 4) {
                    Text(deck.name ?? "Untitled Deck")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let stats = stats {
                        HStack(spacing: 12) {
                            Text("\(stats.total) cards")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if mode == .normal {
                                let availableCards = stats.new + stats.due + stats.learning
                                Text("\(availableCards) available")
                                    .font(.caption)
                                    .foregroundColor(availableCards > 0 ? .blue : .gray)
                            } else {
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Quick stats
                if let stats = stats {
                    VStack(alignment: .trailing, spacing: 2) {
                        if mode == .normal {
                            let availableCards = stats.new + stats.due + stats.learning
                            Text("\(availableCards)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(availableCards > 0 ? .blue : .gray)
                            Text("available")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(stats.total)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text("total")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(uiColor: UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
} 