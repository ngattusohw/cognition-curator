import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            DecksView()
                .tabItem {
                    Image(systemName: "rectangle.stack.fill")
                    Text("Decks")
                }
                .tag(1)
            
            ReviewView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Review")
                }
                .tag(2)
            
            ProgressView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 