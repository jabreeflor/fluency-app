import SwiftUI
import SwiftData

/// Profile + Settings — per Ellis spec
/// Avatar (initials), XP level, stats, settings toggles, subscription management
struct ProfileView: View {
    var user: User
    @Environment(\.modelContext) private var modelContext
    @State private var showPaywall = false
    @State private var showStreakView = false
    @State private var notificationsEnabled = true
    @State private var pronunciationFeedback = true
    @State private var editingName = false
    @State private var nameInput = ""

    private var initials: String {
        let parts = user.username.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)).uppercased() }.joined()
    }

    private var level: Int { max(1, user.totalXP / 100 + 1) }
    private var xpToNextLevel: Int { level * 100 }
    private var xpProgress: Double { Double(user.totalXP % 100) / 100.0 }

    var body: some View {
        NavigationStack {
            ZStack {
                FluencyTheme.surface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Profile header
                        profileHeader
                            .padding(.top, 24)
                            .padding(.bottom, 20)

                        Divider().padding(.horizontal)

                        // Settings sections
                        VStack(spacing: 20) {
                            learningSection
                            notificationsSection
                            subscriptionSection
                            legalSection
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 20)

                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showStreakView) { StreakView(user: user) }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(FluencyTheme.heroGradient)
                    .frame(width: 88, height: 88)

                if initials.isEmpty {
                    Image(systemName: "person.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                } else {
                    Text(initials)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            // Name (tappable to edit)
            Button {
                nameInput = user.username
                editingName = true
            } label: {
                HStack(spacing: 6) {
                    Text(user.username.isEmpty ? "Set your name" : user.username)
                        .font(.system(.title3, design: .default, weight: .bold))
                        .foregroundStyle(user.username.isEmpty ? FluencyTheme.textSecondary : FluencyTheme.textPrimary)
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(FluencyTheme.textSecondary)
                }
            }
            .alert("Your Name", isPresented: $editingName) {
                TextField("Name", text: $nameInput)
                Button("Save") {
                    user.username = nameInput
                    try? modelContext.save()
                }
                Button("Cancel", role: .cancel) {}
            }

            // Level badge + XP progress
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text("Level \(level)")
                        .font(.system(.subheadline, design: .default, weight: .semibold))
                        .foregroundStyle(FluencyTheme.primary)
                    XPBadge(xp: user.totalXP)
                }

                FluencyProgressBar(progress: xpProgress)
                    .frame(width: 200)

                Text("\(user.totalXP % 100) / \(xpToNextLevel) XP to next level")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
            }

            // Quick stats row
            HStack(spacing: 0) {
                QuickStat(value: "\(user.currentStreak)", label: "Streak", icon: "flame.fill", color: .orange)
                Divider().frame(height: 40)
                QuickStat(value: "\(user.totalXP)", label: "XP", icon: "star.fill", color: FluencyTheme.gold)
                Divider().frame(height: 40)
                QuickStat(value: user.isPremium ? "Pro" : "Free", label: "Plan", icon: user.isPremium ? "crown.fill" : "person.fill", color: user.isPremium ? FluencyTheme.gold : FluencyTheme.textSecondary)
            }
            .background(FluencyTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Learning Section

    private var learningSection: some View {
        SettingsGroup(title: "Learning") {
            SettingsRow(icon: "target", iconColor: FluencyTheme.primary, label: "Daily Goal") {
                Text("\(user.dailyXPGoal / 2) min")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
            }

            SettingsRow(icon: "flame.fill", iconColor: .orange, label: "Streak") {
                Button {
                    showStreakView = true
                } label: {
                    Text("\(user.currentStreak) days →")
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(FluencyTheme.primary)
                }
            }
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        SettingsGroup(title: "Preferences") {
            HStack {
                SettingsIconLabel(icon: "bell.fill", color: .red, label: "Daily Reminders")
                Spacer()
                Toggle("", isOn: $notificationsEnabled)
                    .tint(FluencyTheme.primary)
                    .labelsHidden()
            }
            .padding(.vertical, 4)

            HStack {
                SettingsIconLabel(icon: "waveform", color: FluencyTheme.primary, label: "Pronunciation Feedback")
                Spacer()
                Toggle("", isOn: $pronunciationFeedback)
                    .tint(FluencyTheme.primary)
                    .labelsHidden()
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        SettingsGroup(title: "Subscription") {
            if user.isPremium {
                SettingsRow(icon: "crown.fill", iconColor: FluencyTheme.gold, label: "Fluency Pro") {
                    Text("Active")
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(FluencyTheme.success)
                }

                SettingsRow(icon: "arrow.counterclockwise", iconColor: FluencyTheme.textSecondary, label: "Manage Subscription") {
                    EmptyView()
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(FluencyTheme.heroGradient)
                                .frame(width: 32, height: 32)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Pro")
                                .font(FluencyTheme.bodyMedium)
                                .foregroundStyle(FluencyTheme.textPrimary)
                            Text("Unlimited lessons · $9.99/mo")
                                .font(FluencyTheme.captionFont)
                                .foregroundStyle(FluencyTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(FluencyTheme.textSecondary)
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        SettingsGroup(title: "About") {
            SettingsRow(icon: "doc.text", iconColor: FluencyTheme.textSecondary, label: "Privacy Policy") { EmptyView() }
            SettingsRow(icon: "scroll", iconColor: FluencyTheme.textSecondary, label: "Terms of Service") { EmptyView() }
            SettingsRow(icon: "arrow.right.square", iconColor: FluencyTheme.error, label: "Sign Out") { EmptyView() }
        }
    }
}

// MARK: - Settings Group

struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FluencyTheme.textSecondary)
                .kerning(0.8)
                .padding(.leading, 4)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, FluencyTheme.cardPadding)
            .padding(.vertical, 8)
            .background(FluencyTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let label: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack {
            SettingsIconLabel(icon: icon, color: iconColor, label: label)
            Spacer()
            trailing
        }
        .padding(.vertical, 10)
    }
}

struct SettingsIconLabel: View {
    let icon: String
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(color.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(color)
            }
            Text(label)
                .font(FluencyTheme.bodyFont)
        }
    }
}

private struct QuickStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(color)
            Text(value).font(.system(.subheadline, design: .default, weight: .bold))
            Text(label).font(.system(size: 11)).foregroundStyle(FluencyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
