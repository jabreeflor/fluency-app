import SwiftUI

struct ProfileView: View {
    let user: User
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            List {
                // User header
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().fill(FluencyTheme.primary.opacity(0.2)).frame(width: 64, height: 64)
                            Text(String(user.username.prefix(1)).uppercased())
                                .font(.title.bold())
                                .foregroundStyle(FluencyTheme.primary)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.username)
                                .font(FluencyTheme.headlineFont)
                            Text("Level \(max(1, user.totalXP / 100)) · \(user.totalXP) XP")
                                .font(FluencyTheme.captionFont)
                                .foregroundStyle(FluencyTheme.textSecondary)
                            if user.isPremium {
                                Label("Premium", systemImage: "crown.fill")
                                    .font(FluencyTheme.captionFont)
                                    .foregroundStyle(FluencyTheme.gold)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Subscription
                if !user.isPremium {
                    Section {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(FluencyTheme.gold)
                                VStack(alignment: .leading) {
                                    Text("Upgrade to Premium")
                                        .font(FluencyTheme.headlineFont)
                                    Text("All languages + unlimited hearts")
                                        .font(FluencyTheme.captionFont)
                                        .foregroundStyle(FluencyTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(FluencyTheme.textSecondary)
                            }
                        }
                    }
                }

                // Settings
                Section("Settings") {
                    HStack {
                        Label("Daily Goal", systemImage: "flag.fill")
                        Spacer()
                        Text("\(user.dailyXPGoal) XP")
                            .foregroundStyle(FluencyTheme.textSecondary)
                    }
                    Label("Notifications", systemImage: "bell.fill")
                    Label("App Version", systemImage: "info.circle")
                }

                // Learning language
                Section("Language") {
                    HStack {
                        Text("🇪🇸")
                        Text("Spanish")
                        Spacer()
                        Text("Learning")
                            .font(FluencyTheme.captionFont)
                            .foregroundStyle(FluencyTheme.primary)
                    }

                    if !user.isPremium {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Text("🔒 More languages")
                                Spacer()
                                Label("Premium", systemImage: "crown.fill")
                                    .font(FluencyTheme.captionFont)
                                    .foregroundStyle(FluencyTheme.gold)
                            }
                        }
                        .foregroundStyle(FluencyTheme.textSecondary)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}
