import SwiftUI

// MARK: - Expandable Text Component (Simple Toggle)

struct ExpandableText: View {
    let text: String
    let lineLimit: Int
    let font: Font
    let color: Color

    @State private var isExpanded = false

    init(text: String, lineLimit: Int = 3, font: Font = .body, color: Color = .primary) {
        self.text = text
        self.lineLimit = lineLimit
        self.font = font
        self.color = color
    }

    private var shouldShowExpandButton: Bool {
        // Simple, reliable check: if text is longer than estimated lines
        let estimatedCharactersPerLine = 50
        let estimatedTotalCharacters = lineLimit * estimatedCharactersPerLine
        return text.count > estimatedTotalCharacters || text.contains("\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(text)
                .font(font)
                .foregroundColor(color)
                .lineLimit(isExpanded ? nil : lineLimit)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.3), value: isExpanded)

            if shouldShowExpandButton {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(isExpanded ? "Show Less" : "Show More")
                            .font(.caption)
                            .fontWeight(.medium)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                .allowsHitTesting(true)
            }
        }
    }
}

// MARK: - Modal Text View (Alternative)

struct ModalText: View {
    let text: String
    let lineLimit: Int
    let font: Font
    let color: Color

    @State private var showingModal = false

    init(text: String, lineLimit: Int = 3, font: Font = .body, color: Color = .primary) {
        self.text = text
        self.lineLimit = lineLimit
        self.font = font
        self.color = color
    }

    private var shouldShowReadMoreButton: Bool {
        let estimatedCharactersPerLine = 50
        let estimatedTotalCharacters = lineLimit * estimatedCharactersPerLine
        return text.count > estimatedTotalCharacters || text.contains("\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(text)
                .font(font)
                .foregroundColor(color)
                .lineLimit(lineLimit)

            if shouldShowReadMoreButton {
                Button(action: {
                    showingModal = true
                }) {
                    HStack(spacing: 6) {
                        Text("Read Full Text")
                            .font(.caption)
                            .fontWeight(.medium)

                        Image(systemName: "doc.text")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                .allowsHitTesting(true)
                .sheet(isPresented: $showingModal) {
                    NavigationView {
                        ScrollView {
                            Text(text)
                                .font(font)
                                .foregroundColor(color)
                                .padding(20)
                        }
                        .navigationTitle("Full Text")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingModal = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview("ExpandableText Tests") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Short Text (No Expand)").font(.headline)
            ExpandableText(
                text: "This is short text",
                lineLimit: 3,
                font: .body,
                color: .primary
            )
            .padding()
            .background(Color.gray.opacity(0.1))

            Text("Long Text (Should Expand)").font(.headline)
            ExpandableText(
                text: "This is a very long text that should definitely trigger the expand functionality because it contains many words and should exceed the character threshold that we set for determining when to show the expand button. This text is intentionally verbose to test the expandable functionality.",
                lineLimit: 3,
                font: .body,
                color: .primary
            )
            .padding()
            .background(Color.gray.opacity(0.1))

            Text("Multi-line Text (Should Expand)").font(.headline)
            ExpandableText(
                text: "Line 1: This is the first line\nLine 2: This is the second line\nLine 3: This is the third line\nLine 4: This is the fourth line\nLine 5: This should be hidden initially",
                lineLimit: 3,
                font: .body,
                color: .primary
            )
            .padding()
            .background(Color.gray.opacity(0.1))
        }
        .padding()
    }
}
