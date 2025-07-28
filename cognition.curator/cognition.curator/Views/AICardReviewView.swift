import SwiftUI
import UIKit

struct AICardReviewView: View {
    let topic: String
    let deckName: String
    @Binding var generatedCards: [AIGeneratedCard]
    let onDeckCreated: () -> Void
    @State private var currentCardIndex = 0
    @State private var showingEditCard = false
    @State private var editingCard: AIGeneratedCard?
    @State private var showingBulkActions = false
    @State private var isCreatingDeck = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @StateObject private var toastManager = ToastManager()

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authService: AuthenticationService

    init(topic: String, deckName: String, generatedCards: Binding<[AIGeneratedCard]>, onDeckCreated: @escaping () -> Void) {
        self.topic = topic
        self.deckName = deckName
        self._generatedCards = generatedCards
        self.onDeckCreated = onDeckCreated
    }

    private var acceptedCards: [AIGeneratedCard] {
        generatedCards.filter { $0.isAccepted }
    }

    private var currentCard: AIGeneratedCard? {
        guard currentCardIndex < generatedCards.count else { return nil }
        return generatedCards[currentCardIndex]
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Header
                progressHeader

                // Card Review Area
                if let card = currentCard {
                    cardReviewSection(card: card)
                } else {
                    completedReviewSection
                }

                // Action Buttons
                actionButtons
            }
            .background(Color(uiColor: UIColor.systemGroupedBackground))
            .navigationTitle("Review Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Bulk Actions") {
                        showingBulkActions = true
                    }
                    .disabled(generatedCards.isEmpty)
                }
            }
            .sheet(isPresented: $showingEditCard) {
                if let editingCard = editingCard {
                    EditCardView(card: editingCard) { updatedCard in
                        updateCard(updatedCard)
                    }
                }
            }
            .sheet(isPresented: $showingBulkActions) {
                BulkActionsView(cards: $generatedCards)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .toast(manager: toastManager)
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 12) {
            // Topic Info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Topic: \(topic)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Deck: \(deckName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(acceptedCards.count) accepted")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)

                    Text("\(generatedCards.count) total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Progress Bar
            if !generatedCards.isEmpty {
                ProgressView(value: Double(currentCardIndex), total: Double(generatedCards.count))
                    .progressViewStyle(.linear)
                .tint(.blue)

                Text("Card \(currentCardIndex + 1) of \(generatedCards.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(uiColor: UIColor.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    // MARK: - Card Review Section

    private func cardReviewSection(card: AIGeneratedCard) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Card Preview
                cardPreview(card: card)

                // Individual Actions (moved above Card Details)
                individualActions(for: card)

                // Card Details (moved below Individual Actions)
                cardDetails(card: card)

                Spacer(minLength: 100)
            }
            .padding(20)
        }
    }

    private func cardPreview(card: AIGeneratedCard) -> some View {
        VStack(spacing: 16) {
            // Question Side
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Question")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    // Difficulty Badge
                    Text(card.difficulty.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(card.difficulty.color.opacity(0.1))
                        .foregroundColor(card.difficulty.color)
                        .clipShape(Capsule())
                }

                Text(card.question)
                    .font(.body)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: UIColor.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Answer Side
            VStack(alignment: .leading, spacing: 8) {
                Text("Answer")
                    .font(.headline)
                    .fontWeight(.semibold)

                ExpandableText(text: card.answer)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: UIColor.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Explanation (if available)
            if let explanation = card.explanation, !explanation.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Explanation")
                        .font(.headline)
                        .fontWeight(.semibold)

                    ExpandableText(
                        text: explanation,
                        lineLimit: 2,
                        font: .caption,
                        color: .secondary
                    )
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            // Acceptance Indicator
            RoundedRectangle(cornerRadius: 16)
                .stroke(card.isAccepted ? Color.green : Color.clear, lineWidth: 3)
        )
    }

    private func cardDetails(card: AIGeneratedCard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Card Details")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                DetailRow(title: "Status", value: card.isAccepted ? "Accepted" : "Pending Review",
                         valueColor: card.isAccepted ? .green : .orange)

                DetailRow(title: "Modified", value: card.isModified ? "Yes" : "No",
                         valueColor: card.isModified ? .blue : .secondary)

                if !card.tags.isEmpty {
                    DetailRow(title: "Tags", value: card.tags.joined(separator: ", "), valueColor: .secondary)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func individualActions(for card: AIGeneratedCard) -> some View {
        VStack(spacing: 12) {
            Text("Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                // Accept/Reject Toggle
                Button(action: {
                    toggleCardAcceptance(card)
                }) {
                    HStack {
                        Image(systemName: card.isAccepted ? "checkmark.circle.fill" : "checkmark.circle")
                        Text(card.isAccepted ? "Accepted" : "Accept")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(card.isAccepted ? Color.green : Color.green.opacity(0.1))
                    .foregroundColor(card.isAccepted ? .white : .green)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Edit Button
                Button(action: {
                    editingCard = card
                    showingEditCard = true
                }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            HStack(spacing: 12) {
                // Delete Button
                Button(action: {
                    deleteCard(card)
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Generate Similar
                Button(action: {
                    generateSimilarCards(basedOn: card)
                }) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Retry")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    // MARK: - Completed Review Section

    private var completedReviewSection: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            VStack(spacing: 8) {
                Text("Review Complete!")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("You've reviewed all \(generatedCards.count) generated cards")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Summary
            VStack(spacing: 12) {
                HStack {
                    Text("Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }

                VStack(spacing: 8) {
                    SummaryRow(title: "Total Generated", value: "\(generatedCards.count)")
                    SummaryRow(title: "Accepted", value: "\(acceptedCards.count)", valueColor: .green)
                    SummaryRow(title: "Modified", value: "\(generatedCards.filter { $0.isModified }.count)", valueColor: .blue)
                    SummaryRow(title: "Ready for Deck", value: "\(acceptedCards.count)", valueColor: .primary)
                }
            }
            .padding(16)
            .background(Color(uiColor: UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .padding(40)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if currentCard != nil {
                // Navigation Buttons
                HStack(spacing: 16) {
                    Button(action: previousCard) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(uiColor: UIColor.systemGray5))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(currentCardIndex == 0)

                    Button(action: {
                        if currentCardIndex >= generatedCards.count - 1 {
                            // On last card, finish and create deck
                            createDeck()
                        } else {
                            // Not on last card, go to next
                            nextCard()
                        }
                    }) {
                        HStack {
                            if currentCardIndex >= generatedCards.count - 1 {
                                Text("Finish")
                                Image(systemName: "checkmark.circle.fill")
                            } else {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(currentCardIndex >= generatedCards.count - 1 ? Color.green : Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // Create Deck Button (only show if we have accepted cards and not on completion screen)
            if !acceptedCards.isEmpty && currentCard != nil {
                Button(action: createDeck) {
                HStack {
                    if isCreatingDeck {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    Text("Create Deck with \(acceptedCards.count) Cards")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(acceptedCards.isEmpty ? Color.gray : Color.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(acceptedCards.isEmpty || isCreatingDeck)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(Color(uiColor: UIColor.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
    }

    // MARK: - Actions

    private func toggleCardAcceptance(_ card: AIGeneratedCard) {
        if let index = generatedCards.firstIndex(where: { $0.id == card.id }) {
            let wasAccepted = generatedCards[index].isAccepted
            generatedCards[index].isAccepted.toggle()

            // Show appropriate feedback
            if wasAccepted {
                toastManager.show(
                    message: "Card rejected • Won't be added to deck",
                    type: .warning,
                    duration: 2.0
                )
            } else {
                toastManager.show(
                    message: "Card accepted • Will be added to deck",
                    type: .success,
                    duration: 2.0
                )
            }

            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }

    private func updateCard(_ updatedCard: AIGeneratedCard) {
        if let index = generatedCards.firstIndex(where: { $0.id == updatedCard.id }) {
            generatedCards[index] = updatedCard
        }
    }

    private func deleteCard(_ card: AIGeneratedCard) {
        let wasLastCard = currentCardIndex == generatedCards.count - 1
        let cardPosition = currentCardIndex + 1
        let totalCards = generatedCards.count

        // Remove the card
        generatedCards.removeAll { $0.id == card.id }

        // Determine the action and show appropriate feedback
        if generatedCards.isEmpty {
            // No cards left
            currentCardIndex = 0
            toastManager.show(
                message: "Card deleted • All cards reviewed",
                type: .info,
                duration: 2.5
            )
        } else if wasLastCard {
            // We were at the last card, go to the new last card
            currentCardIndex = generatedCards.count - 1
            toastManager.show(
                message: "Card deleted • Moved to previous card",
                type: .success,
                duration: 2.5
            )
        } else {
            // Show next card (index stays the same since array shifted)
            let nextCardPosition = currentCardIndex + 1
            let remainingCards = generatedCards.count
            toastManager.show(
                message: "Card deleted • Showing card \(nextCardPosition) of \(remainingCards)",
                type: .success,
                duration: 2.5
            )
        }

        // Add haptic feedback for better UX
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    private func generateSimilarCards(basedOn card: AIGeneratedCard) {
        // Show loading state feedback
        toastManager.show(
            message: "Generating new card...",
            type: .info,
            duration: 1.5
        )

        Task {
            do {
                // Generate just 1 similar card to replace the current one
                let similarCards = try await AIGenerationService.shared.generateSimilarCards(basedOn: card, count: 1)

                await MainActor.run {
                    if let newCard = similarCards.first {
                        // Replace the current card with the new similar card
                        generatedCards[currentCardIndex] = newCard
                        print("🔄 Replaced card at index \(currentCardIndex) with similar card: \(newCard.question)")

                        // Show success feedback
                        toastManager.show(
                            message: "New card generated • Review updated content",
                            type: .success,
                            duration: 2.5
                        )

                        // Add haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to generate similar card: \(error.localizedDescription)"
                    showingError = true

                    // Also show toast for immediate feedback
                    toastManager.show(
                        message: "Failed to generate new card",
                        type: .error,
                        duration: 3.0
                    )
                }
            }
        }
    }

    private func nextCard() {
        if currentCardIndex < generatedCards.count - 1 {
            currentCardIndex += 1
        }
    }

    private func previousCard() {
        if currentCardIndex > 0 {
            currentCardIndex -= 1
        }
    }

    private func createDeck() {
        guard !acceptedCards.isEmpty else { return }

        isCreatingDeck = true

        // Show loading feedback
        toastManager.show(
            message: "Creating deck with \(acceptedCards.count) cards...",
            type: .info,
            duration: 2.0
        )

        Task {
            do {
                // Create deck via API
                let deckAPIService = DeckAPIService(authService: authService)
                let backendDeck = try await deckAPIService.createDeck(
                    name: deckName,
                    description: "AI-generated deck for \(topic)",
                    category: "AI Generated",
                    color: "#007AFF"
                )

                // Create flashcards for accepted cards using batch API
                let flashcardAPIService = FlashcardAPIService(authService: authService)

                do {
                    // Create comprehensive AI generation prompt for tracking
                    let aiPrompt = "Generated \(acceptedCards.count) flashcards for topic: '\(topic)' with difficulty: \(acceptedCards.first?.difficulty.rawValue ?? "medium")"

                    let backendFlashcards = try await flashcardAPIService.createFlashcardsBatch(
                        deckId: backendDeck.id,
                        cards: acceptedCards,
                        sourceReference: "AI Generated from topic: \(topic)",
                        aiGenerationPrompt: aiPrompt
                    )
                    print("✅ Created \(backendFlashcards.count) flashcards via batch API")
                } catch {
                    print("❌ Failed to create flashcards via batch API: \(error)")
                    throw error
                }

                // Save locally in Core Data
                await MainActor.run {
                    let newDeck = Deck(context: viewContext)
                    newDeck.id = UUID(uuidString: backendDeck.id) ?? UUID()
                    newDeck.name = backendDeck.name
                    newDeck.createdAt = Date()
                    newDeck.isPremium = false
                    newDeck.isSuperset = false

                    // Create local flashcards
                    for card in acceptedCards {
                        let newCard = Flashcard(context: viewContext)
                        newCard.id = UUID()
                        newCard.question = card.question
                        newCard.answer = card.answer
                        newCard.createdAt = Date()
                        newCard.deck = newDeck
                    }

                    do {
                        try viewContext.save()
                    } catch {
                        print("Failed to save deck locally: \(error)")
                    }

                    isCreatingDeck = false

                    // Show success feedback
                    toastManager.show(
                        message: "✅ Deck '\(deckName)' created with \(acceptedCards.count) cards!",
                        type: .success,
                        duration: 3.0
                    )

                    // Add haptic feedback for success
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)

                    // Update widget data after creating AI deck with cards
                    WidgetDataService.shared.refreshAfterAddingCards()

                    onDeckCreated() // Signal deck creation completion

                    // Delay dismiss slightly to show success toast
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }

            } catch {
                await MainActor.run {
                    isCreatingDeck = false
                    errorMessage = "Failed to create deck: \(error.localizedDescription)"
                    showingError = true

                    // Show error toast as well
                    toastManager.show(
                        message: "Failed to create deck",
                        type: .error,
                        duration: 3.0
                    )

                    // Add error haptic feedback
                    let errorFeedback = UINotificationFeedbackGenerator()
                    errorFeedback.notificationOccurred(.error)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct DetailRow: View {
    let title: String
    let value: String
    let valueColor: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    let valueColor: Color

    init(title: String, value: String, valueColor: Color = .primary) {
        self.title = title
        self.value = value
        self.valueColor = valueColor
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Edit Card View

struct EditCardView: View {
    @State private var card: AIGeneratedCard
    let onSave: (AIGeneratedCard) -> Void

    @Environment(\.dismiss) private var dismiss

    init(card: AIGeneratedCard, onSave: @escaping (AIGeneratedCard) -> Void) {
        self._card = State(initialValue: card)
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question")
                            .font(.headline)
                            .fontWeight(.semibold)

                        TextEditor(text: $card.question)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(uiColor: UIColor.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Answer")
                            .font(.headline)
                            .fontWeight(.semibold)

                        TextEditor(text: $card.answer)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(uiColor: UIColor.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Explanation (Optional)")
                            .font(.headline)
                            .fontWeight(.semibold)

                        TextEditor(text: Binding(
                            get: { card.explanation ?? "" },
                            set: { card.explanation = $0.isEmpty ? nil : $0 }
                        ))
                        .frame(minHeight: 60)
                        .padding(8)
                        .background(Color(uiColor: UIColor.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Difficulty")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Picker("Difficulty", selection: $card.difficulty) {
                            ForEach(CardDifficulty.allCases, id: \.self) { difficulty in
                                Text(difficulty.displayName).tag(difficulty)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    Spacer(minLength: 100)
                }
                .padding(20)
            }
            .navigationTitle("Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedCard = card
                        updatedCard.isModified = true
                        onSave(updatedCard)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Bulk Actions View

struct BulkActionsView: View {
    @Binding var cards: [AIGeneratedCard]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Text("Bulk Actions")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Apply actions to multiple cards at once")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    Button(action: acceptAllCards) {
                        actionButtonContent(
                            icon: "checkmark.circle.fill",
                            title: "Accept All Cards",
                            color: .green
                        )
                    }

                    Button(action: rejectAllCards) {
                        actionButtonContent(
                            icon: "x.circle.fill",
                            title: "Reject All Cards",
                            color: .red
                        )
                    }

                    Button(action: resetAllCards) {
                        actionButtonContent(
                            icon: "arrow.clockwise",
                            title: "Reset All to Original",
                            color: .blue
                        )
                    }

                    Button(action: deleteRejectedCards) {
                        actionButtonContent(
                            icon: "trash.fill",
                            title: "Delete Rejected Cards",
                            color: .red
                        )
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("Bulk Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func actionButtonContent(icon: String, title: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func acceptAllCards() {
        for index in cards.indices {
            cards[index].isAccepted = true
        }
        dismiss()
    }

    private func rejectAllCards() {
        for index in cards.indices {
            cards[index].isAccepted = false
        }
        dismiss()
    }

    private func resetAllCards() {
        for index in cards.indices {
            cards[index].isAccepted = true
            cards[index].isModified = false
        }
        dismiss()
    }

    private func deleteRejectedCards() {
        cards.removeAll { !$0.isAccepted }
        dismiss()
    }
}

#Preview {
    AICardReviewView(
        topic: "Swift Programming",
        deckName: "Swift Basics",
        generatedCards: .constant([
            AIGeneratedCard(question: "What is Swift?", answer: "A powerful programming language", difficulty: .medium),
            AIGeneratedCard(question: "What is a variable?", answer: "A storage location with a name", difficulty: .easy),
            AIGeneratedCard(question: "What is inheritance?", answer: "A mechanism to create new classes based on existing ones", difficulty: .hard)
        ])
    ) {
        // Preview completion handler
        print("Deck created in preview")
    }
    .environmentObject(AuthenticationService.shared)
}
