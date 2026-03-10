import SwiftUI
import SwiftData

struct HomeView: View {
    var user: User
    @Query private var lessonResults: [LessonResult]
    @State private var selectedLesson: String?
    @State private var showStreakView = false
    @Environment(\.modelContext) private var modelContext

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = user.username.isEmpty ? "there" : user.username
        switch hour {
        case 0..<12: return "Good morning, \(name) 👋"
        case 12..<17: return "Good afternoon, \(name) 👋"
        default: return "Good evening, \(name) 👋"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FluencyTheme.surface.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // MARK: - Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(greeting)
                                    .font(.system(size: 22, weight: .bold))
                                Text("Keep the momentum going.")
                                    .font(FluencyTheme.captionFont)
                                    .foregroundStyle(FluencyTheme.textSecondary)
                            }
                            Spacer()
                            StreakBadge(streak: user.currentStreak)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // MARK: - Today's Lesson Card
                        TodayLessonCard(user: user)
                            .padding(.horizontal, 20)

                        // MARK: - Streak Section
                        Button { showStreakView = true } label: {
                            StreakSection(user: user)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)

                        // MARK: - Quick Practice
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Practice")
                                .font(.system(.headline, design: .default, weight: .bold))
                                .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    QuickPracticeCard(icon: "text.book.closed.fill", label: "Vocabulary", color: FluencyTheme.primary)
                                    QuickPracticeCard(icon: "waveform", label: "Pronunciation", color: Color(hex: "#6B2DEF"))
                                    QuickPracticeCard(icon: "list.bullet", label: "Grammar Drill", color: FluencyTheme.success)
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        // MARK: - XP Progress Bar
                        XPProgressSection(user: user)
                            .padding(.horizontal, 20)

                        Spacer().frame(height: 80)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showStreakView) { StreakView(user: user) }
        }
    }
}

// MARK: - Today's Lesson Card

private struct TodayLessonCard: View {
    var user: User

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY'S LESSON")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(FluencyTheme.primary.opacity(0.7))
                        .kerning(1.2)
                    Text("Greetings & Basics")
                        .font(.system(.title3, design: .default, weight: .bold))
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(FluencyTheme.heroGradient)
                        .frame(width: 50, height: 50)
                    Text("🇪🇸")
                        .font(.title2)
                }
            }

            HStack(spacing: 12) {
                Label("~8 min", systemImage: "clock")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
                Label("Vocabulary", systemImage: "text.book.closed")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
                Spacer()
                XPBadge(xp: 15)
            }

            FluencyPrimaryButton("Start Lesson") {
                // navigation handled by parent
            }
        }
        .padding(FluencyTheme.cardPadding)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius + 4))
        .shadow(color: FluencyTheme.primary.opacity(0.1), radius: 12, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius + 4)
                .stroke(FluencyTheme.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Streak Section

private struct StreakSection: View {
    var user: User

    private var weekDays: [(label: String, status: DayStatus)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset - 6, to: today)!
            let isToday = calendar.isDateInToday(date)
            let dayLabel = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            // simplified: mark today as blue, past days as green (stub)
            let status: DayStatus = isToday ? .today : .completed
            return (dayLabel, status)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Streak")
                    .font(.system(.headline, design: .default, weight: .bold))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text("\(user.currentStreak)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(FluencyTheme.textPrimary)
                }
            }

            Text("Keep it going")
                .font(FluencyTheme.captionFont)
                .foregroundStyle(FluencyTheme.textSecondary)

            // 7-day dots
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.label) { day in
                    VStack(spacing: 5) {
                        Text(String(day.label.prefix(1)))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(FluencyTheme.textSecondary)
                        Circle()
                            .fill(dotColor(day.status))
                            .frame(width: 28, height: 28)
                            .overlay {
                                if day.status == .today {
                                    Circle().stroke(FluencyTheme.primary, lineWidth: 2)
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(FluencyTheme.cardPadding)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func dotColor(_ status: DayStatus) -> Color {
        switch status {
        case .completed: return FluencyTheme.success
        case .today: return FluencyTheme.primary.opacity(0.2)
        case .missed: return FluencyTheme.border
        }
    }

    enum DayStatus { case completed, today, missed }
}

// MARK: - Quick Practice Card

private struct QuickPracticeCard: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(label)
                .font(.system(.caption, design: .default, weight: .medium))
                .foregroundStyle(FluencyTheme.textPrimary)
        }
        .frame(width: 90)
        .padding(.vertical, 14)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - XP Progress

private struct XPProgressSection: View {
    var user: User

    private var level: Int { max(1, user.totalXP / 100 + 1) }
    private var levelXP: Int { level * 100 }
    private var progress: Double { Double(user.totalXP % 100) / 100.0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Level \(level)")
                    .font(.system(.subheadline, design: .default, weight: .semibold))
                Spacer()
                Text("\(user.totalXP % 100) / 100 XP")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
            }
            FluencyProgressBar(progress: progress)
        }
    }
}
