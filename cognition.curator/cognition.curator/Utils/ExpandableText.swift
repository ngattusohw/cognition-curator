import SwiftUI

// MARK: - Expandable Text Component

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
        // Show expand button if text has multiple lines or is long
        let lines = text.components(separatedBy: .newlines)
        let hasMultipleLines = lines.count > lineLimit
        let hasLongLines = lines.contains { $0.count > 80 } // Reduced from 100
        let isTotallyLong = text.count > lineLimit * 40 // Reduced from 60

        return hasMultipleLines || hasLongLines || isTotallyLong
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(font)
                .foregroundColor(color)
                .lineLimit(isExpanded ? nil : lineLimit)
                .multilineTextAlignment(.leading)

            if shouldShowExpandButton {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Show Less" : "Show More")
                            .font(.caption)
                            .fontWeight(.medium)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
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
