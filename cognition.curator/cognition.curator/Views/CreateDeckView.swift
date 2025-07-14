import SwiftUI
import CoreData

struct CreateDeckView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var deckName = ""
    @State private var isSuperset = false
    @State private var isPremium = false
    @State private var showingAIGeneration = false
    @State private var aiTopic = ""
    @State private var isGenerating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Basic info form
                    basicInfoSection
                    
                    // AI generation section
                    aiGenerationSection
                    
                    // Superset options
                    supersetSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Create Deck")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createDeck()
                    }
                    .fontWeight(.semibold)
                    .disabled(deckName.isEmpty)
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
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Create a New Deck")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start building your knowledge with flashcards")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Deck Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Enter deck name...", text: $deckName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
            }
            
            Toggle(isOn: $isPremium) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Premium Deck")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Enable CloudKit sync and advanced features")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var aiGenerationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Generation")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Let AI create flashcards for you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Enter a topic (e.g., 'French vocabulary')", text: $aiTopic)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        showingAIGeneration = true
                    }) {
                        Text("Generate")
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(aiTopic.isEmpty || isGenerating)
                }
                
                if isGenerating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text("Generating flashcards...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showingAIGeneration) {
            AIGenerationView(topic: aiTopic, deckName: deckName)
        }
    }
    
    private var supersetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Superset Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $isSuperset) {
                    HStack {
                        Image(systemName: "rectangle.stack.fill")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Create as Superset")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Combine multiple decks into one")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                if isSuperset {
                    Text("You can add other decks to this superset after creation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 32)
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func createDeck() {
        guard !deckName.isEmpty else { return }
        
        let newDeck = Deck(context: viewContext)
        newDeck.id = UUID()
        newDeck.name = deckName
        newDeck.createdAt = Date()
        newDeck.isPremium = isPremium
        newDeck.isSuperset = isSuperset
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to create deck: \(error.localizedDescription)"
            showingError = true
        }
    }
}

struct AIGenerationView: View {
    let topic: String
    let deckName: String
    @Environment(\.dismiss) private var dismiss
    @State private var generatedCards: [FlashcardData] = []
    @State private var isGenerating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isGenerating {
                    generatingView
                } else if generatedCards.isEmpty {
                    startGenerationView
                } else {
                    generatedCardsView
                }
            }
            .padding(20)
            .navigationTitle("AI Generation")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var startGenerationView: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Generate Flashcards")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("AI will create flashcards for: \(topic)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                generateCards()
            }) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Start Generation")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var generatingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            
            VStack(spacing: 8) {
                Text("Generating flashcards...")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("This may take a few moments")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var generatedCardsView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Generated Cards")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(generatedCards.count) cards")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(generatedCards.enumerated()), id: \.offset) { index, card in
                        GeneratedCardRow(card: card, index: index)
                    }
                }
            }
            
            Button(action: {
                // Save cards to deck
                dismiss()
            }) {
                Text("Add to Deck")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func generateCards() {
        isGenerating = true
        
        // Simulate AI generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            generatedCards = [
                FlashcardData(question: "What is \(topic)?", answer: "A fundamental concept in \(topic)"),
                FlashcardData(question: "How does \(topic) work?", answer: "It operates through various mechanisms"),
                FlashcardData(question: "Why is \(topic) important?", answer: "Because it provides significant value"),
                FlashcardData(question: "When should you use \(topic)?", answer: "In appropriate contexts and situations"),
                FlashcardData(question: "What are the benefits of \(topic)?", answer: "Multiple advantages and improvements")
            ]
            isGenerating = false
        }
    }
}

struct GeneratedCardRow: View {
    let card: FlashcardData
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Card \(index + 1)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
                
                Spacer()
            }
            
            Text(card.question)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(card.answer)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    CreateDeckView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
