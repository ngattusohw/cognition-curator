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
        // Simple heuristic: if text has more than a certain number of characters or newlines
        let characterThreshold = lineLimit * 80 // Approximately 80 chars per line
        let newlineCount = text.components(separatedBy: .newlines).count - 1
        return text.count > characterThreshold || newlineCount >= lineLimit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(font)
                .foregroundColor(color)
                .lineLimit(isExpanded ? nil : lineLimit)
                .fixedSize(horizontal: false, vertical: false)

            if shouldShowExpandButton {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
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