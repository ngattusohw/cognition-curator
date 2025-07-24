import SwiftUI
import UIKit
import CoreData

struct AddCardView: View {
    let deck: Deck
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthenticationService

    @State private var question = ""
    @State private var answer = ""
    @State private var isCreating = false
    @State private var showingError = false
    @State private var errorMessage = ""

    // AI Answer Generation
    @State private var isGeneratingAnswer = false
    @State private var generatedAnswer: AIAnswerResponse?
    @State private var showingAIAnswer = false
    @State private var showingPremiumRequired = false
    @StateObject private var aiService = AIGenerationService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared

    private var flashcardAPIService: FlashcardAPIService {
        FlashcardAPIService(authService: authService)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Form
                formSection

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .background(Color(uiColor: UIColor.systemGroupedBackground))
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isCreating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button("Add") {
                            Task {
                                await addCard()
                            }
                        }
                        .fontWeight(.semibold)
                        .disabled(question.isEmpty || answer.isEmpty)
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingAIAnswer) {
                if let generatedAnswer = generatedAnswer {
                    AIAnswerReviewView(
                        question: question,
                        aiAnswer: generatedAnswer,
                        onAccept: { acceptedAnswer in
                            answer = acceptedAnswer
                            showingAIAnswer = false
                        },
                        onReject: {
                            showingAIAnswer = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showingPremiumRequired) {
                PremiumRequiredView(
                    feature: .aiAnswerGeneration,
                    onUpgrade: {
                        // Handle upgrade action
                        showingPremiumRequired = false
                    },
                    onDismiss: {
                        showingPremiumRequired = false
                    }
                )
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("Add New Card")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create a new flashcard for '\(deck.name ?? "Untitled Deck")'")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var formSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Question")
                    .font(.headline)
                    .fontWeight(.semibold)

                TextField("Enter your question...", text: $question, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Answer")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    // AI Generate Answer Button
                    Button(action: generateAIAnswer) {
                        HStack(spacing: 4) {
                            if isGeneratingAnswer {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "brain.head.profile")
                                    .font(.caption)
                            }
                            Text("AI Generate")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(subscriptionService.isPremium ? Color.purple : Color.gray)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                    .disabled(question.isEmpty || isGeneratingAnswer)
                    .opacity(question.isEmpty ? 0.6 : 1.0)
                }

                TextField("Enter the answer...", text: $answer, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)

                // AI Tip
                if !subscriptionService.isPremium {
                    HStack {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("AI answer generation available with Premium")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.top, 4)
                } else if question.isEmpty {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Enter a question to generate an AI answer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }

            // Preview card
            if !question.isEmpty || !answer.isEmpty {
                cardPreview
            }
        }
        .padding(20)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var cardPreview: some View {
        VStack(spacing: 16) {
            Text("Preview")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Question")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    if question.isEmpty {
                        Text("Your question will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ExpandableText(
                            text: question,
                            lineLimit: 3,
                            font: .subheadline,
                            color: .primary
                        )
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Answer")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    if answer.isEmpty {
                        Text("Your answer will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ExpandableText(
                            text: answer,
                            lineLimit: 3,
                            font: .subheadline,
                            color: .primary
                        )
                    }
                }
            }
            .padding(16)
            .background(Color(uiColor: UIColor.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

        private func generateAIAnswer() {
        guard !question.isEmpty else { return }

        // Check premium access
        if subscriptionService.requiresPremium(.aiAnswerGeneration) {
            showingPremiumRequired = true
            return
        }

        isGeneratingAnswer = true

        Task {
            do {
                let aiAnswer = try await aiService.generateAnswer(
                    for: question,
                    context: nil,
                    difficulty: .medium,
                    deckTopic: deck.name
                )

                await MainActor.run {
                    generatedAnswer = aiAnswer
                    showingAIAnswer = true
                    isGeneratingAnswer = false
                }
            } catch {
                await MainActor.run {
                    isGeneratingAnswer = false
                    errorMessage = "Failed to generate answer: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    private func addCard() async {
        guard !question.isEmpty && !answer.isEmpty else { return }

        await MainActor.run {
            isCreating = true
        }

        do {
            // Create flashcard via backend API
            guard let deckId = deck.id?.uuidString else {
                throw FlashcardAPIError.invalidURL
            }

            let backendFlashcard = try await flashcardAPIService.createFlashcard(
                deckId: deckId,
                front: question,
                back: answer,
                hint: nil,
                explanation: nil,
                tags: [],
                sourceReference: nil
            )

            // Also save locally in Core Data for offline access
            await MainActor.run {
                let newCard = Flashcard(context: viewContext)
                newCard.id = UUID(uuidString: backendFlashcard.id) ?? UUID()
                newCard.question = backendFlashcard.front
                newCard.answer = backendFlashcard.back
                newCard.createdAt = Date()
                newCard.deck = deck

                do {
                    try viewContext.save()
                } catch {
                    print("Failed to save flashcard locally: \(error)")
                }

                isCreating = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isCreating = false
                errorMessage = "Failed to add card: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
}

#Preview {
    AddCardView(deck: Deck())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
