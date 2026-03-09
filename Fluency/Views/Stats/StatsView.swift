import SwiftUI

struct StatsView: View {
    let user: User

    private var completedLessons: Int { user.progress.filter { $0.isCompleted }.count }
    private var totalXP: Int { user.totalXP }
    private var avgAccuracy: Double {
        let results = user.lessonResults.filter { $0.totalQuestions > 0 }
        guard !results.isEmpty else { return 0 }
        return results.map { $0.accuracy }.reduce(0, +) / Double(results.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(title: "Streak", value: "\(user.currentStreak)", unit: "days", icon: "flame.fill", color: .orange)
                        StatCard(title: "Total XP", value: "\(totalXP)", unit: "points", icon: "star.fill", color: FluencyTheme.gold)
                        StatCard(title: "Lessons", value: "\(completedLessons)", unit: "complete", icon: "book.fill", color: FluencyTheme.primary)
                        StatCard(title: "Accuracy", value: "\(Int(avgAccuracy * 100))%", unit: "avg", icon: "target", color: .blue)
                    }

                    // Recent activity
                    if !user.lessonResults.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Activity")
                                .font(FluencyTheme.headlineFont)
                                .padding(.horizontal)

                            ForEach(user.lessonResults.sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }.prefix(5)) { result in
                                RecentResultRow(result: result)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // SR Cards overview
                    let totalCards = user.srCards.count
                    let learnedCards = user.srCards.filter { $0.repetition >= 3 }.count
                    if totalCards > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Vocabulary")
                                .font(FluencyTheme.headlineFont)
                                .padding(.horizontal)
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(totalCards) words")
                                        .font(FluencyTheme.headlineFont)
                                    Text("\(learnedCards) mastered")
                                        .font(FluencyTheme.captionFont)
                                        .foregroundStyle(FluencyTheme.textSecondary)
                                }
                                Spacer()
                                CircularProgress(progress: Double(learnedCards) / Double(totalCards), size: 60)
                            }
                            .padding(FluencyTheme.cardPadding)
                            .background(FluencyTheme.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(FluencyTheme.surface.ignoresSafeArea())
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
            Text(unit)
                .font(FluencyTheme.captionFont)
                .foregroundStyle(FluencyTheme.textSecondary)
            Text(title)
                .font(FluencyTheme.captionFont)
                .foregroundStyle(FluencyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FluencyTheme.cardPadding)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct RecentResultRow: View {
    let result: LessonResult

    var body: some View {
        HStack {
            Image(systemName: result.accuracy >= 0.8 ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(result.accuracy >= 0.8 ? FluencyTheme.primary : FluencyTheme.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(result.lessonId)
                    .font(FluencyTheme.bodyFont)
                if let date = result.completedAt {
                    Text(date, style: .relative)
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(FluencyTheme.textSecondary)
                }
            }
            Spacer()
            Text("+\(result.xpEarned) XP")
                .font(FluencyTheme.captionFont)
                .foregroundStyle(FluencyTheme.gold)
        }
        .padding(12)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct CircularProgress: View {
    let progress: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().stroke(FluencyTheme.border, lineWidth: 4)
            Circle().trim(from: 0, to: progress)
                .stroke(FluencyTheme.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6), value: progress)
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.28, weight: .bold))
        }
        .frame(width: size, height: size)
    }
}
