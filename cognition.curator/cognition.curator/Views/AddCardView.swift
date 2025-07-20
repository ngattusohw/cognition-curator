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
                Text("Answer")
                    .font(.headline)
                    .fontWeight(.semibold)

                TextField("Enter the answer...", text: $answer, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
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

                    Text(question.isEmpty ? "Your question will appear here" : question)
                        .font(.subheadline)
                        .foregroundColor(question.isEmpty ? .secondary : .primary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Answer")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text(answer.isEmpty ? "Your answer will appear here" : answer)
                        .font(.subheadline)
                        .foregroundColor(answer.isEmpty ? .secondary : .primary)
                }
            }
            .padding(16)
            .background(Color(uiColor: UIColor.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
