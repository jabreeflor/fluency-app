import SwiftUI

struct HomeView: View {
    let user: User
    @State private var showLesson: Bool = false
    @State private var continueLessonContent: LessonContent?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Streak Banner
                    StreakBannerView(streak: user.currentStreak)

                    // Daily Goal Ring
                    DailyGoalView(progress: user.dailyGoalProgress, todayXP: user.todayXP, goalXP: user.dailyXPGoal)

                    // Hearts
                    HeartsView(hearts: user.hearts)

                    // Continue Lesson CTA
                    if let lesson = nextLesson() {
                        ContinueLessonCard(lesson: lesson) {
                            continueLessonContent = lesson
                            showLesson = true
                        }
                    }

                    // XP Milestone
                    XPProgressView(totalXP: user.totalXP)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(FluencyTheme.surface.ignoresSafeArea())
            .navigationTitle("¡Hola! 👋")
            .navigationBarTitleDisplayMode(.large)
        }
        .fullScreenCover(item: $continueLessonContent) { lesson in
            LessonSessionView(lesson: lesson, user: user)
        }
    }

    private func nextLesson() -> LessonContent? {
        guard let course = ContentLoader.shared.loadSpanishCourse() else { return nil }
        let completedIds = Set(user.progress.filter { $0.isCompleted }.map { $0.lessonId })

        for unit in course.units.sorted(by: { $0.order < $1.order }) {
            for lessonRef in unit.lessons.sorted(by: { $0.order < $1.order }) {
                if !completedIds.contains(lessonRef.id) {
                    return ContentLoader.shared.loadLesson(id: lessonRef.id)
                }
            }
        }
        return nil
    }
}

// MARK: - Subviews

struct StreakBannerView: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("🔥")
                .font(.system(size: 36))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) day streak")
                    .font(FluencyTheme.headlineFont)
                    .foregroundStyle(FluencyTheme.textPrimary)
                Text(streak == 0 ? "Start learning to begin a streak!" : "Keep it going!")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
            }
            Spacer()
        }
        .padding(FluencyTheme.cardPadding)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct DailyGoalView: View {
    let progress: Double
    let todayXP: Int
    let goalXP: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Goal")
                    .font(FluencyTheme.headlineFont)
                Spacer()
                Text("\(todayXP) / \(goalXP) XP")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(FluencyTheme.border)
                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(FluencyTheme.gold)
                        .frame(width: geo.size.width * progress, height: 12)
                        .animation(.spring(response: 0.6), value: progress)
                }
            }
            .frame(height: 12)
        }
        .padding(FluencyTheme.cardPadding)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct HeartsView: View {
    let hearts: Int

    var body: some View {
        HStack(spacing: 8) {
            Text("Lives")
                .font(FluencyTheme.headlineFont)
            Spacer()
            ForEach(0..<5, id: \.self) { i in
                Text(i < hearts ? "❤️" : "🖤")
                    .font(.title2)
            }
        }
        .padding(FluencyTheme.cardPadding)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct ContinueLessonCard: View {
    let lesson: LessonContent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Continue Learning")
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(lesson.name)
                        .font(FluencyTheme.headlineFont)
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "play.fill")
                    .foregroundStyle(.white)
                    .font(.title2)
            }
            .padding(FluencyTheme.cardPadding)
            .background(FluencyTheme.primary)
            .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        }
    }
}

struct XPProgressView: View {
    let totalXP: Int

    var level: Int { max(1, totalXP / 100) }
    var progressInLevel: Double { Double(totalXP % 100) / 100.0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Level \(level)")
                    .font(FluencyTheme.headlineFont)
                Spacer()
                Text("\(totalXP) XP total")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8).fill(FluencyTheme.border).frame(height: 12)
                    RoundedRectangle(cornerRadius: 8).fill(FluencyTheme.primary)
                        .frame(width: geo.size.width * progressInLevel, height: 12)
                        .animation(.spring(response: 0.6), value: progressInLevel)
                }
            }
            .frame(height: 12)
        }
        .padding(FluencyTheme.cardPadding)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
