import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @StateObject private var offlineSyncService = OfflineSyncService.shared
    @StateObject private var progressDataService = ProgressDataService.shared

    @State private var showingSettings = false
    @State private var showingAbout = false
    @State private var showingSupport = false
    @State private var showingSubscription = false
    @State private var showingDataExport = false
    @State private var showingSignOutAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeaderSection

                    // Subscription Status
                    subscriptionSection

                    // Sync & Data Status
                    syncStatusSection

                    // Account Management
                    accountSection

                    // App Settings
                    settingsSection

                    // Help & Support
                    supportSection

                    // About & Legal
                    aboutSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(uiColor: UIColor.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out? Your data will remain synced to your account.")
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Profile Avatar & Info
            HStack(spacing: 16) {
                // Avatar Circle
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)

                    if let user = authService.currentUser {
                        Text(user.name.prefix(1).uppercased())
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let user = authService.currentUser {
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Image(systemName: user.appleId != nil ? "applelogo" : "envelope.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(user.appleId != nil ? "Apple ID" : "Email Account")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Not signed in")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Sign in to sync your progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            // Quick Stats Row
            if authService.isAuthenticated {
                HStack(spacing: 20) {
                    ProfileStatItem(
                        value: "\(progressDataService.progressData?.currentStreak ?? 0)",
                        label: "Day Streak",
                        icon: "flame.fill",
                        color: .red
                    )

                    ProfileStatItem(
                        value: "\(progressDataService.progressData?.totalCardsReviewed ?? 0)",
                        label: "Cards Reviewed",
                        icon: "brain.head.profile",
                        color: .blue
                    )

                    ProfileStatItem(
                        value: "\(Int((progressDataService.progressData?.averageAccuracy ?? 0.0) * 100))%",
                        label: "Accuracy",
                        icon: "target",
                        color: .green
                    )
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(Color(uiColor: UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Subscription", icon: "crown.fill", color: .orange)

            VStack(spacing: 12) {
                if let user = authService.currentUser, user.isPremium {
                    // Premium Status
                    ProfileMenuItem(
                        title: "Premium Active",
                        subtitle: "Unlimited decks, advanced features, offline sync",
                        icon: "checkmark.seal.fill",
                        iconColor: .green,
                        showChevron: false
                    )

                    ProfileMenuItem(
                        title: "Manage Subscription",
                        subtitle: "View billing, change plan, or cancel",
                        icon: "creditcard.fill",
                        iconColor: .blue
                    ) {
                        showingSubscription = true
                    }
                } else {
                    // Free Plan
                    ProfileMenuItem(
                        title: "Free Plan",
                        subtitle: "Limited to 5 decks",
                        icon: "gift.fill",
                        iconColor: .blue,
                        showChevron: false
                    )

                    ProfileMenuItem(
                        title: "Upgrade to Premium",
                        subtitle: "Unlock unlimited decks and advanced features",
                        icon: "crown.fill",
                        iconColor: .orange,
                        showAccessory: {
                            AnyView(
                                Text("$4.99/mo")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.1))
                                    .clipShape(Capsule())
                            )
                        }
                    ) {
                        showingSubscription = true
                    }
                }
            }
        }
    }

    // MARK: - Sync Status Section

    private var syncStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Data & Sync", icon: "icloud.fill", color: .blue)

            VStack(spacing: 12) {
                // Network Status
                ProfileMenuItem(
                    title: NetworkMonitor.shared.isConnected ? "Online" : "Offline",
                    subtitle: NetworkMonitor.shared.isConnected ? "All features available" : "Local mode active",
                    icon: NetworkMonitor.shared.isConnected ? "wifi" : "wifi.slash",
                    iconColor: NetworkMonitor.shared.isConnected ? .green : .orange,
                    showChevron: false
                )

                // Pending Sync Operations
                if offlineSyncService.pendingOperationsCount > 0 {
                    ProfileMenuItem(
                        title: "Pending Sync",
                        subtitle: "\(offlineSyncService.pendingOperationsCount) items waiting to sync",
                        icon: "icloud.and.arrow.up",
                        iconColor: .orange
                    ) {
                        Task {
                            await offlineSyncService.forceSyncAll()
                        }
                    }
                }

                // Last Sync
                if let lastSync = offlineSyncService.lastSyncDate {
                    ProfileMenuItem(
                        title: "Last Sync",
                        subtitle: RelativeDateTimeFormatter().localizedString(for: lastSync, relativeTo: Date()),
                        icon: "checkmark.icloud.fill",
                        iconColor: .green,
                        showChevron: false
                    )
                }

                // Data Export
                ProfileMenuItem(
                    title: "Export Data",
                    subtitle: "Download your flashcards and progress",
                    icon: "square.and.arrow.up.fill",
                    iconColor: .blue
                ) {
                    showingDataExport = true
                }
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Account", icon: "person.crop.circle.fill", color: .blue)

            VStack(spacing: 12) {
                if authService.isAuthenticated {
                    ProfileMenuItem(
                        title: "Account Details",
                        subtitle: "View and edit your profile information",
                        icon: "person.text.rectangle.fill",
                        iconColor: .blue
                    ) {
                        // Navigate to account details
                    }

                    ProfileMenuItem(
                        title: "Privacy Settings",
                        subtitle: "Manage your data and privacy preferences",
                        icon: "hand.raised.fill",
                        iconColor: .purple
                    ) {
                        // Navigate to privacy settings
                    }

                    ProfileMenuItem(
                        title: "Sign Out",
                        subtitle: "Sign out of your account",
                        icon: "rectangle.portrait.and.arrow.right.fill",
                        iconColor: .red
                    ) {
                        showingSignOutAlert = true
                    }
                } else {
                    ProfileMenuItem(
                        title: "Sign In",
                        subtitle: "Sign in to sync your progress across devices",
                        icon: "person.crop.circle.badge.plus",
                        iconColor: .blue
                    ) {
                        // Navigate to sign in
                    }
                }
            }
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Settings", icon: "gear.circle.fill", color: .gray)

            VStack(spacing: 12) {
                ProfileMenuItem(
                    title: "Study Settings",
                    subtitle: "Configure review algorithms and limits",
                    icon: "brain.head.profile.fill",
                    iconColor: .blue
                ) {
                    showingSettings = true
                }

                ProfileMenuItem(
                    title: "Notifications",
                    subtitle: "Manage reminder and study notifications",
                    icon: "bell.fill",
                    iconColor: .orange
                ) {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }

                ProfileMenuItem(
                    title: "Appearance",
                    subtitle: "Dark mode and display preferences",
                    icon: "paintbrush.fill",
                    iconColor: .purple
                ) {
                    showingSettings = true
                }

                ProfileMenuItem(
                    title: "Accessibility",
                    subtitle: "Voice, text size, and accessibility options",
                    icon: "accessibility.fill",
                    iconColor: .green
                ) {
                    showingSettings = true
                }
            }
        }
    }

    // MARK: - Support Section

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Help & Support", icon: "questionmark.circle.fill", color: .blue)

            VStack(spacing: 12) {
                ProfileMenuItem(
                    title: "Help Center",
                    subtitle: "FAQs and user guides",
                    icon: "book.fill",
                    iconColor: .blue
                ) {
                    showingSupport = true
                }

                ProfileMenuItem(
                    title: "Contact Support",
                    subtitle: "Get help from our team",
                    icon: "envelope.fill",
                    iconColor: .green
                ) {
                    showingSupport = true
                }

                ProfileMenuItem(
                    title: "Feature Requests",
                    subtitle: "Suggest new features and improvements",
                    icon: "lightbulb.fill",
                    iconColor: .yellow
                ) {
                    showingSupport = true
                }

                ProfileMenuItem(
                    title: "Report a Bug",
                    subtitle: "Help us improve the app",
                    icon: "ant.fill",
                    iconColor: .red
                ) {
                    showingSupport = true
                }
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "About", icon: "info.circle.fill", color: .gray)

            VStack(spacing: 12) {
                ProfileMenuItem(
                    title: "App Version",
                    subtitle: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
                    icon: "app.badge.fill",
                    iconColor: .blue,
                    showChevron: false
                )

                ProfileMenuItem(
                    title: "What's New",
                    subtitle: "See the latest features and improvements",
                    icon: "sparkles",
                    iconColor: .purple
                ) {
                    showingAbout = true
                }

                ProfileMenuItem(
                    title: "Terms of Service",
                    subtitle: "Read our terms and conditions",
                    icon: "doc.text.fill",
                    iconColor: .gray
                ) {
                    showingAbout = true
                }

                ProfileMenuItem(
                    title: "Privacy Policy",
                    subtitle: "Learn how we protect your data",
                    icon: "shield.fill",
                    iconColor: .green
                ) {
                    showingAbout = true
                }

                ProfileMenuItem(
                    title: "Acknowledgments",
                    subtitle: "Third-party libraries and contributors",
                    icon: "heart.fill",
                    iconColor: .red
                ) {
                    showingAbout = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ProfileStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text(value)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()
        }
    }
}

struct ProfileMenuItem: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let showChevron: Bool
    let showAccessory: (() -> AnyView)?
    let action: (() -> Void)?

    init(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        showChevron: Bool = true,
        showAccessory: (() -> AnyView)? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.showChevron = showChevron
        self.showAccessory = showAccessory
        self.action = action
    }

    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(iconColor)
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Accessory
                if let showAccessory = showAccessory {
                    showAccessory()
                } else if showChevron && action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
}

// MARK: - Placeholder Views

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("Subscription Management")
                    .font(.title)
                    .padding()

                Text("Premium subscription features coming soon!")
                    .foregroundColor(.secondary)

                Spacer()
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationService.shared)
}