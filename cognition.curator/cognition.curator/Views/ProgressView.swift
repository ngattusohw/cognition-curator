import SwiftUI
import CoreData

struct ProgressView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTimeframe: Timeframe = .week
    @State private var currentStreak = 0
    @State private var totalCardsReviewed = 0
    @State private var averageAccuracy = 0.0
    @State private var studyTime = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats overview
                    statsOverview
                    
                    // Streak card
                    streakCard
                    
                    // Charts section
                    chartsSection
                    
                    // Recent activity
                    recentActivitySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadProgressData()
            }
        }
    }
    
    private var statsOverview: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Overview")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(Timeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.displayName).tag(timeframe)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatOverviewCard(
                    title: "Cards Reviewed",
                    value: "\(totalCardsReviewed)",
                    icon: "brain.head.profile",
                    color: .blue
                )
                
                StatOverviewCard(
                    title: "Accuracy",
                    value: "\(Int(averageAccuracy * 100))%",
                    icon: "target",
                    color: .green
                )
                
                StatOverviewCard(
                    title: "Study Time",
                    value: "\(studyTime)m",
                    icon: "clock.fill",
                    color: .orange
                )
                
                StatOverviewCard(
                    title: "Streak",
                    value: "\(currentStreak) days",
                    icon: "flame.fill",
                    color: .red
                )
            }
        }
    }
    
    private var streakCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Keep it up! Consistency is key to learning.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(currentStreak)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.orange)
                    
                    Text("days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Streak visualization
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    Circle()
                        .fill(day < min(currentStreak, 7) ? Color.orange : Color(.systemGray5))
                        .frame(width: 12, height: 12)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var chartsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Learning Trends")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 20) {
                // Daily activity chart
                DailyActivityChart()
                
                // Accuracy trend chart
                AccuracyTrendChart()
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { index in
                    ActivityRowView(
                        activity: ActivityItem(
                            type: index % 2 == 0 ? .review : .create,
                            title: index % 2 == 0 ? "Reviewed 15 cards" : "Created 'Math Basics' deck",
                            time: Date().addingTimeInterval(-Double(index * 3600)),
                            count: index % 2 == 0 ? 15 : nil
                        )
                    )
                }
            }
        }
    }
    
    private func loadProgressData() {
        // TODO: Load actual data from Core Data
        currentStreak = 7
        totalCardsReviewed = 156
        averageAccuracy = 0.85
        studyTime = 45
    }
}

struct StatOverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct DailyActivityChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.7))
                            .frame(height: CGFloat.random(in: 20...80))
                        
                        Text(["M", "T", "W", "T", "F", "S", "S"][day])
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct AccuracyTrendChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accuracy Trend")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.opacity(0.7))
                            .frame(height: CGFloat.random(in: 30...60))
                        
                        Text(["M", "T", "W", "T", "F", "S", "S"][day])
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct ActivityRowView: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.type.icon)
                .font(.title3)
                .foregroundColor(activity.type.color)
                .frame(width: 32, height: 32)
                .background(activity.type.color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(formatTime(activity.time))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let count = activity.count {
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

enum Timeframe: CaseIterable {
    case week, month, year
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
}

enum ActivityType {
    case review, create
    
    var icon: String {
        switch self {
        case .review: return "brain.head.profile"
        case .create: return "plus.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .review: return .blue
        case .create: return .green
        }
    }
}

struct ActivityItem {
    let type: ActivityType
    let title: String
    let time: Date
    let count: Int?
}

#Preview {
    ProgressView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 