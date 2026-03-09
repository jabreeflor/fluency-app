import SwiftUI

/// 4-tab bar per Ellis spec: Home / Lessons / Progress / Profile
struct MainTabView: View {
    var user: User

    var body: some View {
        TabView {
            HomeView(user: user)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            LearnView(user: user)
                .tabItem {
                    Label("Lessons", systemImage: "book.fill")
                }

            StatsView(user: user)
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }

            ProfileView(user: user)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(FluencyTheme.primary)
    }
}
