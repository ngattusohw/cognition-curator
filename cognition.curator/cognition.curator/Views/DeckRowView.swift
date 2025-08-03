import SwiftUI
import UIKit
import CoreData

struct DeckRowView: View {
    let deck: Deck
    @State private var cardCount = 0

    var body: some View {
        HStack(spacing: 16) {
            // Deck icon
            VStack {
                Image(systemName: deck.isSuperset ? "rectangle.stack.fill" : "rectangle.stack")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Deck info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(deck.name ?? "Untitled Deck")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    // Status badges
                    HStack(spacing: 4) {
                        if deck.isCurrentlySilenced {
                            Image(systemName: "speaker.slash.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }

                        if deck.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                }

                                Text("\(cardCount) cards")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if deck.isCurrentlySilenced {
                    Text(deck.silenceDescription)
                        .font(.caption)
                        .foregroundColor(.orange)
                } else if let createdAt = deck.createdAt {
                    Text("Created \(formatDate(createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .onAppear {
            cardCount = deck.flashcards?.count ?? 0
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    DeckRowView(deck: Deck())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .padding()
}
