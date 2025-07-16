import SwiftUI
import UIKit
import CoreData

struct ReviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var deepLinkHandler: DeepLinkHandler
    @Binding var forceReview: Bool
    @Binding var selectedTab: Int
    
    @State private var cardsToReview: [Flashcard] = []
    @State private var currentCardIndex = 0
    @State private var showingAnswer = false
    @State private var isFlipping = false
    @State private var showingReviewComplete = false
    @State private var reviewSessionStartTime = Date()
    @State private var cardsReviewed = 0
    @State private var isDeckSpecificReview = false
    @State private var currentReviewMode: ReviewMode = .normal
    
    // Swipe gesture state
    @State private var dragOffset = CGSize.zero
    @State private var isBeingDragged = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if cardsToReview.isEmpty {
                    emptyStateView
                } else if currentCardIndex >= cardsToReview.count {
                    reviewCompleteView
                } else {
                    reviewSessionView
                }
            }
            .background(Color(uiColor: UIColor.systemGroupedBackground))
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                checkForDeckReview()
                
                if forceReview {
                    loadCardsForReview(force: true)
                    forceReview = false
                } else {
                    loadCardsForReview()
                }
            }
            .onChange(of: deepLinkHandler.targetCardId) { cardId in
                if let cardId = cardId {
                    loadSpecificCard(cardId: cardId)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("All caught up!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("You've completed all your reviews for today. Great job!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                // Force load more cards
                loadCardsForReview(force: true)
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Review Anyway")
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
    
    private var reviewSessionView: some View {
        VStack(spacing: 24) {
            // Progress header
            progressHeader
            
            // Card view
            cardView
            
            // Difficulty buttons
            if showingAnswer {
                difficultyButtons
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Card \(currentCardIndex + 1) of \(cardsToReview.count)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    // Review mode indicator
                    HStack(spacing: 4) {
                        Image(systemName: reviewModeIcon)
                            .font(.caption2)
                        Text(currentReviewMode.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                        
                        if isDeckSpecificReview {
                            Text("• Custom")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(reviewModeColor.opacity(0.15))
                    .foregroundColor(reviewModeColor)
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // Skip button
                Button(action: {
                    skipCurrentCard()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.forward")
                            .font(.caption)
                        Text("Skip")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                Text("\(Int(Date().timeIntervalSince(reviewSessionStartTime) / 60))m")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(currentCardIndex), total: Double(cardsToReview.count))
                .progressViewStyle(.linear)
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
    }
    
    private var reviewModeIcon: String {
        switch currentReviewMode {
        case .normal: return isDeckSpecificReview ? "rectangle.stack" : "checkmark.circle"
        case .practice: return "repeat.circle"
        case .cram: return "bolt.circle"
        }
    }
    
    private var reviewModeColor: Color {
        switch currentReviewMode {
        case .normal: return isDeckSpecificReview ? .purple : .blue
        case .practice: return .green
        case .cram: return .orange
        }
    }
    
    private var cardView: some View {
        VStack(spacing: 20) {
            // Card container
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(uiColor: UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 24) {
                    // Card content
                    VStack(spacing: 16) {
                        Text(showingAnswer ? "Answer" : "Question")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(uiColor: UIColor.systemGray6))
                            .clipShape(Capsule())
                        
                        Text(showingAnswer ? 
                             cardsToReview[currentCardIndex].answer ?? "No answer" :
                                cardsToReview[currentCardIndex].question ?? "No question")
                            .font(.title2)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .opacity(isFlipping ? 0 : 1)
                            .animation(.easeInOut(duration: 0.2), value: isFlipping)
                    }
                    
                    // Tap instruction
                    VStack(spacing: 8) {
                        if !showingAnswer {
                            Text("Tap to reveal answer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Tap to show question again")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Visual indicator
                        Image(systemName: showingAnswer ? "arrow.counterclockwise" : "eye")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .opacity(0.6)
                    }
                    .padding(.top, 20)
                }
                .padding(40)
                
                // Swipe indicator overlay
                if isBeingDragged && abs(dragOffset.width) > 20 {
                    VStack {
                        Spacer()
                        HStack {
                            if dragOffset.width > 0 {
                                Spacer()
                            }
                            
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.forward.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.orange)
                                
                                Text("Skip")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                
                                Text("\(Int(abs(dragOffset.width)))px")
                                    .font(.caption)
                                    .foregroundColor(.orange.opacity(0.7))
                            }
                            .opacity(min(abs(dragOffset.width) / 100.0, 1.0))
                            .scaleEffect(min(abs(dragOffset.width) / 100.0, 1.2))
                            
                            if dragOffset.width < 0 {
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
            }
            .frame(height: 300)
            .scaleEffect(isFlipping ? 0.95 : 1.0)
            .offset(dragOffset)
            .rotationEffect(.degrees(dragOffset.width / 20.0))
            .animation(.easeInOut(duration: 0.3), value: isFlipping)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        if !isFlipping {
                            withAnimation(.interactiveSpring()) {
                                dragOffset = value.translation
                                isBeingDragged = true
                            }
                        }
                    }
                    .onEnded { value in
                        if !isFlipping {
                            // Check if swipe was far enough to skip
                            if abs(value.translation.width) > 80 {
                                // Skip the card
                                skipCurrentCard()
                            } else {
                                // Snap back to center
                                withAnimation(.spring()) {
                                    dragOffset = .zero
                                }
                            }
                        }
                        isBeingDragged = false
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        if !isBeingDragged && !isFlipping && abs(dragOffset.width) < 10 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isFlipping = true
                            }
                            
                            // Flip the content after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                showingAnswer.toggle()
                                
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isFlipping = false
                                }
                            }
                        }
                    }
            )
            
            // Swipe instruction
            VStack(spacing: 4) {
                Text("Swipe left or right to skip (80px+)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(0.7)
                
                if isBeingDragged {
                    Text("Dragging: \(Int(abs(dragOffset.width)))px")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    private var difficultyButtons: some View {
        VStack(spacing: 16) {
            Text("How well did you know this?")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                    DifficultyButton(
                        difficulty: difficulty,
                        action: {
                            handleDifficultySelection(difficulty)
                        }
                    )
                }
            }
        }
        .padding(.top, 20)
    }
    
    private var reviewCompleteView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("Review Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("You reviewed \(cardsReviewed) cards in \(formatDuration(Date().timeIntervalSince(reviewSessionStartTime)))")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    // Start new review session
                    currentCardIndex = 0
                    showingAnswer = false
                    loadCardsForReview()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Review More")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: {
                    // Go back to home
                    selectedTab = 0 // Navigate to the home tab
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("Back to Home")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(uiColor: UIColor.systemGray5))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private func checkForDeckReview() {
        // Check if there's a pending deck-specific review
        if let deckIdStrings = UserDefaults.standard.array(forKey: "pendingDeckReview") as? [String],
           let modeString = UserDefaults.standard.string(forKey: "pendingReviewMode"),
           let mode = ReviewMode(rawValue: modeString) {
            
            let deckIds = deckIdStrings.compactMap { UUID(uuidString: $0) }
            if !deckIds.isEmpty {
                isDeckSpecificReview = true
                currentReviewMode = mode
                
                cardsToReview = SpacedRepetitionService.shared.getCardsFromDecks(
                    context: viewContext,
                    deckIds: deckIds,
                    mode: mode,
                    limit: 50
                )
                
                // Clear the pending review
                UserDefaults.standard.removeObject(forKey: "pendingDeckReview")
                UserDefaults.standard.removeObject(forKey: "pendingReviewMode")
                
                currentCardIndex = 0
                showingAnswer = false
                reviewSessionStartTime = Date()
                cardsReviewed = 0
                dragOffset = .zero
                isBeingDragged = false
                
                print("🎯 Started deck-specific review: \(cardsToReview.count) cards from \(deckIds.count) decks (\(mode.displayName) mode)")
                return
            }
        }
        
        // No deck-specific review, use normal loading
        isDeckSpecificReview = false
        currentReviewMode = SpacedRepetitionService.shared.currentReviewMode
    }
    
    private func loadCardsForReview(force: Bool = false) {
        // Don't reload if we already have a deck-specific review
        if isDeckSpecificReview && !cardsToReview.isEmpty {
            return
        }
        
        cardsToReview = SpacedRepetitionService.shared.getCardsForTodaySession(
            context: viewContext, 
            limit: force ? 50 : nil, 
            force: force
        )
        currentCardIndex = 0
        showingAnswer = false
        reviewSessionStartTime = Date()
        cardsReviewed = 0
        
        // Reset drag state
        dragOffset = .zero
        isBeingDragged = false
    }
    
    private func loadSpecificCard(cardId: UUID) {
        // Find the card by ID
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", cardId as CVarArg)
        request.fetchLimit = 1
        
        do {
            let foundCards = try viewContext.fetch(request)
            if let specificCard = foundCards.first {
                // Load this specific card along with other due cards
                let otherCards = SpacedRepetitionService.shared.getCardsForTodaySession(
                    context: viewContext,
                    limit: 19 // Limit to 19 so we have room for the specific card
                )
                
                // Create new cards array with the specific card first
                var newCardsToReview = [specificCard]
                
                // Add other cards if they're not the same card
                for card in otherCards {
                    if card.id != cardId {
                        newCardsToReview.append(card)
                    }
                }
                
                cardsToReview = newCardsToReview
                currentCardIndex = 0
                showingAnswer = false
                reviewSessionStartTime = Date()
                cardsReviewed = 0
                isDeckSpecificReview = false
                
                // Reset drag state
                dragOffset = .zero
                isBeingDragged = false
            }
        } catch {
            print("Error loading specific card: \(error)")
            // Fallback to normal review
            loadCardsForReview(force: true)
        }
    }
    
    private func skipCurrentCard() {
        guard currentCardIndex < cardsToReview.count else { return }
        
        // Animate card sliding out
        withAnimation(.easeInOut(duration: 0.3)) {
            dragOffset = CGSize(width: dragOffset.width > 0 ? 400 : -400, height: 0)
        }
        
        // Move to next card after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentCardIndex += 1
            showingAnswer = false
            isFlipping = false
            
            // Reset drag state
            withAnimation(.easeInOut(duration: 0.2)) {
                dragOffset = .zero
                isBeingDragged = false
            }
            
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    private func handleDifficultySelection(_ difficulty: DifficultyLevel) {
        guard currentCardIndex < cardsToReview.count else { return }
        
        let card = cardsToReview[currentCardIndex]
        
        // Calculate next review using SM-2 algorithm
        _ = SpacedRepetitionService.shared.calculateNextReview(for: card, difficulty: difficulty.rawValue)
        
        // Save context
        PersistenceController.shared.save()
        
        // Move to next card
        cardsReviewed += 1
        currentCardIndex += 1
        showingAnswer = false
        isFlipping = false
        
        // Reset drag state
        dragOffset = .zero
        isBeingDragged = false
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }
}

struct DifficultyButton: View {
    let difficulty: DifficultyLevel
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: difficultyIcon)
                    .font(.title2)
                    .foregroundColor(difficultyColor)
                
                Text(difficulty.displayName)
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
    
    private var difficultyIcon: String {
        switch difficulty {
        case .again: return "xmark.circle.fill"
        case .hard: return "exclamationmark.triangle.fill"
        case .good: return "checkmark.circle.fill"
        case .easy: return "star.fill"
        }
    }
    
    private var difficultyColor: Color {
        switch difficulty {
        case .again: return .red
        case .hard: return .orange
        case .good: return .green
        case .easy: return .blue
        }
    }
}

#Preview {
    ReviewView(forceReview: .constant(false), selectedTab: .constant(0))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
