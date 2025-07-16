import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthenticationService
    @State private var selectedReviewMode: ReviewMode
    @State private var maxNewCardsPerDay: Double
    @State private var maxReviewCardsPerDay: Double
    @State private var showingPremiumRequired = false
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    
    init() {
        let service = SpacedRepetitionService.shared
        _selectedReviewMode = State(initialValue: service.currentReviewMode)
        _maxNewCardsPerDay = State(initialValue: Double(service.maxNewCardsPerDay))
        _maxReviewCardsPerDay = State(initialValue: Double(service.maxReviewCardsPerDay))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    reviewModeSection
                    dailyLimitsSection
                    algorithmInfoSection
                    accountSection
                    aboutSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(uiColor: UIColor.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("Premium Feature", isPresented: $showingPremiumRequired) {
            Button("OK") { }
            Button("Upgrade") {
                // TODO: Handle premium upgrade
            }
        } message: {
            Text("This review mode requires a premium subscription to unlock advanced features.")
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authService.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out? Your progress will be saved to your account.")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await authService.deleteAccount()
                }
            }
        } message: {
            Text("This action cannot be undone. All your decks, cards, and progress will be permanently deleted.")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "gear.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Review Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Customize your learning experience")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var reviewModeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Review Mode")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(ReviewMode.allCases, id: \.self) { mode in
                    ReviewModeRow(
                        mode: mode,
                        isSelected: selectedReviewMode == mode,
                        onTap: {
                            if mode.isPremium {
                                showingPremiumRequired = true
                            } else {
                                selectedReviewMode = mode
                            }
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var dailyLimitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Limits")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("New Cards per Day")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(maxNewCardsPerDay))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    Slider(value: $maxNewCardsPerDay, in: 5...50, step: 5)
                        .accentColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Review Cards per Day")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(maxReviewCardsPerDay))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    
                    Slider(value: $maxReviewCardsPerDay, in: 20...200, step: 10)
                        .accentColor(.green)
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var algorithmInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spaced Repetition")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(
                    icon: "brain.head.profile.fill",
                    title: "Algorithm",
                    value: "Enhanced SM-2",
                    color: .purple
                )
                
                InfoRow(
                    icon: "clock.fill",
                    title: "Learning Steps",
                    value: "1m → 10m → 1d",
                    color: .orange
                )
                
                InfoRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Ease Factor",
                    value: "Adaptive (1.3-3.0)",
                    color: .green
                )
            }
        }
        .padding(20)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("This app uses an enhanced version of the SM-2 spaced repetition algorithm with learning phases. New cards start with short intervals (1 minute, 10 minutes) before graduating to daily reviews. The algorithm adapts to your performance, making difficult cards appear more frequently.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding(20)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // User info
                if let user = authService.currentUser {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(
                            icon: "person.crop.circle.fill",
                            title: "Name",
                            value: user.name,
                            color: .blue
                        )
                        
                        InfoRow(
                            icon: "envelope.fill",
                            title: "Email",
                            value: user.email,
                            color: .blue
                        )
                        
                        InfoRow(
                            icon: "calendar.badge.plus",
                            title: "Member Since",
                            value: DateFormatter.monthYear.string(from: user.createdAt),
                            color: .green
                        )
                        
                        if user.isPremium {
                            InfoRow(
                                icon: "crown.fill",
                                title: "Premium Member",
                                value: "Active",
                                color: .orange
                            )
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Account actions
                    VStack(spacing: 12) {
                        Button(action: { showingSignOutAlert = true }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                Text("Sign Out")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        Button(action: { showingDeleteAccountAlert = true }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 24)
                                
                                Text("Delete Account")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
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
    
    private func saveSettings() {
        let service = SpacedRepetitionService.shared
        
        // Only save non-premium modes if not premium user
        if !selectedReviewMode.isPremium {
            service.currentReviewMode = selectedReviewMode
        }
        
        service.maxNewCardsPerDay = Int(maxNewCardsPerDay)
        service.maxReviewCardsPerDay = Int(maxReviewCardsPerDay)
    }
}

struct ReviewModeRow: View {
    let mode: ReviewMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(mode.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if mode.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
} 