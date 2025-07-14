import SwiftUI
import UIKit
import CoreData

struct ReviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var cardsToReview: [Flashcard] = []
    @State private var currentCardIndex = 0
    @State private var showingAnswer = false
    @State private var isFlipping = false
    @State private var showingReviewComplete = false
    @State private var reviewSessionStartTime = Date()
    @State private var cardsReviewed = 0
    
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
                loadCardsForReview()
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
                Text("Card \(currentCardIndex + 1) of \(cardsToReview.count)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
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
                    }
                    
                    // Tap to reveal hint
                    if !showingAnswer {
                        Text("Tap to reveal answer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 20)
                    }
                }
                .padding(40)
            }
            .frame(height: 300)
            .rotation3DEffect(
                .degrees(showingAnswer ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .onTapGesture {
                if !showingAnswer && !isFlipping {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showingAnswer = true
                    }
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
    
    private func loadCardsForReview(force: Bool = false) {
        cardsToReview = SpacedRepetitionService.shared.getCardsForTodaySession(context: viewContext, limit: force ? 50 : 20)
        currentCardIndex = 0
        showingAnswer = false
        reviewSessionStartTime = Date()
        cardsReviewed = 0
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
    ReviewView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
