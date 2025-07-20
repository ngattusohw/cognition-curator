import SwiftUI

struct PremiumRequiredView: View {
    let feature: SubscriptionService.PremiumFeature
    let onUpgrade: () -> Void
    let onDismiss: () -> Void

    @StateObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()

                // Premium Icon
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }

                    Text("Premium Feature")
                        .font(.title)
                        .fontWeight(.bold)
                }

                // Feature Description
                VStack(spacing: 16) {
                    Text(feature.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)

                    Text(feature.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                // Premium Benefits
                VStack(alignment: .leading, spacing: 12) {
                    Text("Premium includes:")
                        .font(.headline)
                        .fontWeight(.semibold)

                    PremiumBenefitRow(
                        icon: "brain.head.profile.fill",
                        title: "AI Answer Generation",
                        description: "Get intelligent answers for your questions"
                    )

                    PremiumBenefitRow(
                        icon: "icloud.and.arrow.down.fill",
                        title: "Offline Sync",
                        description: "Sync your progress when offline"
                    )

                    PremiumBenefitRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Advanced Analytics",
                        description: "Detailed learning insights and progress"
                    )

                    PremiumBenefitRow(
                        icon: "rectangle.stack.fill",
                        title: "Unlimited Decks",
                        description: "Create as many decks as you want"
                    )
                }
                .padding(20)
                .background(Color(uiColor: UIColor.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            do {
                                try await subscriptionService.purchasePremium()
                                onUpgrade()
                            } catch {
                                print("Purchase failed: \(error)")
                            }
                        }
                    }) {
                        HStack {
                            if subscriptionService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "crown.fill")
                            }
                            Text("Upgrade to Premium")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(subscriptionService.isLoading)

                    Button(action: {
                        Task {
                            do {
                                try await subscriptionService.restorePurchases()
                            } catch {
                                print("Restore failed: \(error)")
                            }
                        }
                    }) {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .disabled(subscriptionService.isLoading)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .padding(20)
            .background(Color(uiColor: UIColor.systemGroupedBackground))
            .navigationTitle("Premium Required")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

struct PremiumBenefitRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    PremiumRequiredView(
        feature: .aiAnswerGeneration,
        onUpgrade: { },
        onDismiss: { }
    )
}