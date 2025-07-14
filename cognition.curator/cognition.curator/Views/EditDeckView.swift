import SwiftUI
import UIKit
import CoreData

struct EditDeckView: View {
    let deck: Deck
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var deckName: String
    @State private var isPremium: Bool
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(deck: Deck) {
        self.deck = deck
        self._deckName = State(initialValue: deck.name ?? "")
        self._isPremium = State(initialValue: deck.isPremium)
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
            .navigationTitle("Edit Deck")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDeck()
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
            Image(systemName: "pencil.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Edit Deck")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Modify your deck settings")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Deck Name")
                    .font(.headline)
                    .fontWeight(.semibold)
                
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
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func saveDeck() {
        guard !deckName.isEmpty else { return }
        
        deck.name = deckName
        deck.isPremium = isPremium
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save deck: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    EditDeckView(deck: Deck())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
