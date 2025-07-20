import SwiftUI

struct AIAnswerReviewView: View {
    let question: String
    let aiAnswer: AIAnswerResponse
    let onAccept: (String) -> Void
    let onReject: () -> Void

    @State private var editedAnswer: String
    @State private var isEditing = false
    @Environment(\.dismiss) private var dismiss

    init(question: String, aiAnswer: AIAnswerResponse, onAccept: @escaping (String) -> Void, onReject: @escaping () -> Void) {
        self.question = question
        self.aiAnswer = aiAnswer
        self.onAccept = onAccept
        self.onReject = onReject
        self._editedAnswer = State(initialValue: aiAnswer.answer)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Question Context
                    questionSection

                    // AI Answer Preview/Edit
                    answerSection

                    // AI Details
                    aiDetailsSection

                    // Action Buttons
                    actionButtons

                    Spacer(minLength: 100)
                }
                .padding(20)
            }
            .background(Color(uiColor: UIColor.systemGroupedBackground))
            .navigationTitle("AI Generated Answer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onReject()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile.fill")
                .font(.system(size: 48))
                .foregroundColor(.purple)

            Text("AI Generated Answer")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Review and edit the AI-generated answer below")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Question Section

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Question")
                .font(.headline)
                .fontWeight(.semibold)

            Text(question)
                .font(.body)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: UIColor.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Answer Section

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Generated Answer")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                // Confidence Badge
                ConfidenceBadge(confidence: aiAnswer.confidence)
            }

            if isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit Answer")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    TextEditor(text: $editedAnswer)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(Color(uiColor: UIColor.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(editedAnswer)
                        .font(.body)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.purple.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                        )

                    if let explanation = aiAnswer.explanation, !explanation.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Explanation")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            Text(explanation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(8)
                                .background(Color.blue.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - AI Details Section

    private var aiDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Generation Details")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                                AIDetailRow(
                    title: "Model",
                    value: aiAnswer.modelVersion,
                    icon: "brain.head.profile"
                )

                AIDetailRow(
                    title: "Generation Time",
                    value: String(format: "%.1fs", aiAnswer.generationTime),
                    icon: "clock"
                )

                AIDetailRow(
                    title: "Difficulty",
                    value: aiAnswer.difficulty.capitalized,
                    icon: "chart.bar"
                )

                if !aiAnswer.suggestedTags.isEmpty {
                    HStack {
                        Image(systemName: "tag")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Tags:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(aiAnswer.suggestedTags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.purple.opacity(0.1))
                                        .foregroundColor(.purple)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Accept Button
            Button(action: {
                onAccept(editedAnswer)
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Accept Answer")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 12) {
                // Edit Toggle
                Button(action: {
                    isEditing.toggle()
                }) {
                    HStack {
                        Image(systemName: isEditing ? "checkmark" : "pencil")
                        Text(isEditing ? "Finish Edit" : "Edit Answer")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Reject Button
                Button(action: {
                    onReject()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Reject")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ConfidenceBadge: View {
    let confidence: Double

    private var confidenceColor: Color {
        if confidence >= 0.9 {
            return .green
        } else if confidence >= 0.8 {
            return .orange
        } else {
            return .red
        }
    }

    private var confidenceText: String {
        if confidence >= 0.9 {
            return "High"
        } else if confidence >= 0.8 {
            return "Medium"
        } else {
            return "Low"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "chart.bar.fill")
                .font(.caption2)
            Text("\(confidenceText) (\(Int(confidence * 100))%)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(confidenceColor.opacity(0.1))
        .foregroundColor(confidenceColor)
        .clipShape(Capsule())
    }
}

struct AIDetailRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    AIAnswerReviewView(
        question: "What is a fuel pump in automotive systems?",
        aiAnswer: AIAnswerResponse(
            answer: "A fuel pump is a mechanical or electrical device that moves fuel from the tank to the engine, creating the necessary pressure for proper fuel delivery.",
            explanation: "Modern vehicles use electric fuel pumps for better efficiency and control.",
            confidence: 0.92,
            sources: [],
            difficulty: "medium",
            generationTime: 1.5,
            modelVersion: "gpt-4-preview",
            suggestedTags: ["pump", "component", "automotive"]
        ),
        onAccept: { _ in },
        onReject: { }
    )
}