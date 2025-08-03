import SwiftUI
import CoreData

enum SilenceDuration: String, CaseIterable {
    case oneHour = "1h"
    case fourHours = "4h"
    case oneDay = "1d"
    case threeDays = "3d"
    case oneWeek = "1w"
    case twoWeeks = "2w"
    case oneMonth = "1mo"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .oneHour: return "1 Hour"
        case .fourHours: return "4 Hours"
        case .oneDay: return "1 Day"
        case .threeDays: return "3 Days"
        case .oneWeek: return "1 Week"
        case .twoWeeks: return "2 Weeks"
        case .oneMonth: return "1 Month"
        case .custom: return "Custom"
        }
    }

    var timeInterval: TimeInterval? {
        switch self {
        case .oneHour: return 60 * 60
        case .fourHours: return 4 * 60 * 60
        case .oneDay: return 24 * 60 * 60
        case .threeDays: return 3 * 24 * 60 * 60
        case .oneWeek: return 7 * 24 * 60 * 60
        case .twoWeeks: return 14 * 24 * 60 * 60
        case .oneMonth: return 30 * 24 * 60 * 60
        case .custom: return nil
        }
    }
}

struct DeckSilenceView: View {
    let deck: Deck
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var toastManager = ToastManager()

    @State private var selectedSilenceType: DeckSilenceType = .permanent
    @State private var selectedDuration: SilenceDuration = .oneDay
    @State private var customEndDate = Date().addingTimeInterval(24 * 60 * 60) // Default to 1 day from now
    @State private var showingCustomDatePicker = false
    @State private var isProcessing = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection

                ScrollView {
                    VStack(spacing: 24) {
                        // Current Status
                        currentStatusSection

                        // Silence Options
                        silenceOptionsSection

                        // Duration Selection (if temporary)
                        if selectedSilenceType == .temporary {
                            durationSelectionSection
                        }

                        // Custom Date Picker (if custom duration)
                        if selectedSilenceType == .temporary && selectedDuration == .custom {
                            customDateSection
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }

                // Action Buttons
                actionButtonsSection
            }
            .background(Color(uiColor: UIColor.systemGroupedBackground))
            .navigationTitle("Deck Silence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .toast(manager: toastManager)
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "speaker.slash.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text(deck.name ?? "Unknown Deck")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text("Manage when this deck appears in reviews")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(Color(uiColor: UIColor.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var currentStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Status")
                .font(.headline)
                .fontWeight(.semibold)

            HStack {
                Image(systemName: deck.isCurrentlySilenced ? "speaker.slash.fill" : "speaker.2.fill")
                    .foregroundColor(deck.isCurrentlySilenced ? .orange : .green)

                VStack(alignment: .leading, spacing: 2) {
                    Text(deck.isCurrentlySilenced ? "Silenced" : "Active")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(deck.isCurrentlySilenced ? .orange : .green)

                    Text(deck.silenceDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var silenceOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Silence Type")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                SilenceOptionRow(
                    type: .permanent,
                    isSelected: selectedSilenceType == .permanent,
                    action: { selectedSilenceType = .permanent }
                )

                SilenceOptionRow(
                    type: .temporary,
                    isSelected: selectedSilenceType == .temporary,
                    action: { selectedSilenceType = .temporary }
                )
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var durationSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Duration")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(SilenceDuration.allCases, id: \.self) { duration in
                    DurationOptionView(
                        duration: duration,
                        isSelected: selectedDuration == duration,
                        action: {
                            selectedDuration = duration
                            if duration == .custom {
                                showingCustomDatePicker = true
                            }
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var customDateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom End Date")
                .font(.headline)
                .fontWeight(.semibold)

            DatePicker(
                "Silence until",
                selection: $customEndDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if deck.isCurrentlySilenced {
                // Unsilence button
                Button(action: unsilenceDeck) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "speaker.2.fill")
                        }
                        Text("Unsilence Deck")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isProcessing)
            }

            // Apply silence button
            Button(action: applySilence) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "speaker.slash.fill")
                    }
                    Text(deck.isCurrentlySilenced ? "Update Silence" : "Apply Silence")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.orange)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isProcessing || (selectedSilenceType == .temporary && selectedDuration == .custom && customEndDate <= Date()))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(Color(uiColor: UIColor.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
    }

    // MARK: - Actions

    private func applySilence() {
        isProcessing = true

        switch selectedSilenceType {
        case .permanent:
            deck.silencePermanently()

        case .temporary:
            let endDate: Date
            if selectedDuration == .custom {
                endDate = customEndDate
            } else {
                endDate = Date().addingTimeInterval(selectedDuration.timeInterval ?? 0)
            }
            deck.silenceTemporarily(until: endDate)
        }

        do {
            try viewContext.save()

            let message = selectedSilenceType == .permanent ?
                "Deck silenced permanently" :
                "Deck silenced until \(formatDate(deck.silenceEndDate!))"

            toastManager.show(
                message: message,
                type: .success,
                duration: 3.0
            )

            // Add haptic feedback
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }

        } catch {
            toastManager.show(
                message: "Failed to save silence settings",
                type: .error,
                duration: 3.0
            )
        }

        isProcessing = false
    }

    private func unsilenceDeck() {
        isProcessing = true

        deck.unsilence()

        do {
            try viewContext.save()

            toastManager.show(
                message: "Deck unsilenced successfully",
                type: .success,
                duration: 3.0
            )

            // Add haptic feedback
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }

        } catch {
            toastManager.show(
                message: "Failed to unsilence deck",
                type: .error,
                duration: 3.0
            )
        }

        isProcessing = false
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct SilenceOptionRow: View {
    let type: DeckSilenceType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(type == .permanent ?
                         "Deck will not appear in reviews until manually unsilenced" :
                         "Deck will be silenced for a specific duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DurationOptionView: View {
    let duration: SilenceDuration
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(duration.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(uiColor: UIColor.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DeckSilenceView(deck: Deck())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
