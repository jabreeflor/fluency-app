import SwiftUI

struct MainTabView: View {
    let user: User
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(user: user)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            LearnView(user: user)
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }
                .tag(1)

            ReviewView(user: user)
                .tabItem {
                    Label("Review", systemImage: "arrow.triangle.2.circlepath")
                }
                .tag(2)

            StatsView(user: user)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(3)

            ProfileView(user: user)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .tint(FluencyTheme.primary)
    }
}
