import SwiftUI
import SwiftData
import Charts

/// Progress tab — XP over time, accuracy chart, lesson history
struct StatsView: View {
    var user: User
    @Query(sort: \LessonResult.completedAt) private var results: [LessonResult]

    private var last7DaysXP: [(day: String, xp: Int)] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let xp = results
                .filter { $0.completedAt != nil && $0.completedAt! >= dayStart && $0.completedAt! < dayEnd }
                .reduce(0) { $0 + $1.xpEarned }
            let label = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            return (label, xp)
        }
    }

    private var last7DaysAccuracy: [(day: String, pct: Double)] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let dayResults = results.filter {
                $0.completedAt != nil && $0.completedAt! >= dayStart && $0.completedAt! < dayEnd
            }
            let avgScore = dayResults.isEmpty ? 0.0 : dayResults.map(\.score).reduce(0, +) / Double(dayResults.count)
            let label = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            return (label, avgScore * 100)
        }
    }

    private var totalLessons: Int { results.count }
    private var avgAccuracy: Int {
        guard !results.isEmpty else { return 0 }
        return Int((results.map(\.score).reduce(0, +) / Double(results.count)) * 100)
    }
    private var level: Int { max(1, user.totalXP / 100 + 1) }

    var body: some View {
        NavigationStack {
            ZStack {
                FluencyTheme.surface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Hero stats
                        heroStats

                        // XP chart
                        xpChart

                        // Accuracy chart
                        accuracyChart

                        // Recent lessons
                        recentLessons

                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Hero Stats

    private var heroStats: some View {
        VStack(spacing: 16) {
            // Level progress
            VStack(spacing: 8) {
                HStack {
                    Text("Level \(level)")
                        .font(.system(.headline, design: .default, weight: .bold))
                    Spacer()
                    Text("\(user.totalXP % 100) / \(level * 100) XP")
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(FluencyTheme.textSecondary)
                }
                FluencyProgressBar(progress: Double(user.totalXP % 100) / Double(level * 100))
            }

            // Stats grid
            HStack(spacing: 12) {
                BigStatCard(value: "\(user.totalXP)", label: "Total XP", icon: "star.fill", color: FluencyTheme.gold)
                BigStatCard(value: "\(totalLessons)", label: "Lessons", icon: "book.fill", color: FluencyTheme.primary)
                BigStatCard(value: "\(avgAccuracy)%", label: "Accuracy", icon: "target", color: FluencyTheme.success)
                BigStatCard(value: "\(user.currentStreak)", label: "Streak", icon: "flame.fill", color: .orange)
            }
        }
        .padding(FluencyTheme.cardPadding)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - XP Chart

    private var xpChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("XP This Week")
                .font(.system(.headline, design: .default, weight: .bold))

            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(last7DaysXP, id: \.day) { item in
                        BarMark(
                            x: .value("Day", item.day),
                            y: .value("XP", item.xp)
                        )
                        .foregroundStyle(FluencyTheme.heroGradient)
                        .cornerRadius(6)
                    }
                }
                .frame(height: 140)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel().font(FluencyTheme.captionFont)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(FluencyTheme.border)
                        AxisValueLabel().font(FluencyTheme.captionFont)
                    }
                }
            } else {
                // Fallback for older iOS
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(last7DaysXP, id: \.day) { item in
                        VStack(spacing: 4) {
                            Capsule()
                                .fill(FluencyTheme.heroGradient)
                                .frame(width: 28, height: max(4, CGFloat(item.xp) / 2))
                            Text(item.day.prefix(1))
                                .font(.system(size: 10))
                                .foregroundStyle(FluencyTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 100)
            }
        }
        .padding(FluencyTheme.cardPadding)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    // MARK: - Accuracy Chart

    private var accuracyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accuracy This Week")
                .font(.system(.headline, design: .default, weight: .bold))

            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(last7DaysAccuracy, id: \.day) { item in
                        LineMark(
                            x: .value("Day", item.day),
                            y: .value("Accuracy", item.pct)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(FluencyTheme.success)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        AreaMark(
                            x: .value("Day", item.day),
                            y: .value("Accuracy", item.pct)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(FluencyTheme.success.opacity(0.12))
                    }
                }
                .frame(height: 120)
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel().font(FluencyTheme.captionFont)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 50, 100]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(FluencyTheme.border)
                        AxisValueLabel().font(FluencyTheme.captionFont)
                    }
                }
            } else {
                Text("\(avgAccuracy)% average accuracy")
                    .font(FluencyTheme.bodyMedium)
                    .foregroundStyle(FluencyTheme.success)
            }
        }
        .padding(FluencyTheme.cardPadding)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    // MARK: - Recent Lessons

    private var recentLessons: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Lessons")
                .font(.system(.headline, design: .default, weight: .bold))

            if results.isEmpty {
                Text("No lessons completed yet. Start your first lesson!")
                    .font(FluencyTheme.bodyFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(results.suffix(5).reversed(), id: \.id) { result in
                    RecentLessonRow(result: result)
                }
            }
        }
    }
}

// MARK: - Big Stat Card

struct BigStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.caption).foregroundStyle(color)
            Text(value).font(.system(.subheadline, design: .default, weight: .bold))
            Text(label).font(.system(size: 10)).foregroundStyle(FluencyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Recent Lesson Row

struct RecentLessonRow: View {
    let result: LessonResult

    private var scoreColor: Color {
        result.score >= 0.8 ? FluencyTheme.success : result.score >= 0.6 ? .orange : FluencyTheme.error
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(result.lessonId.replacingOccurrences(of: "-", with: " ").capitalized)
                    .font(FluencyTheme.bodyMedium)
                if let date = result.completedAt {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(FluencyTheme.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(Int(result.score * 100))%")
                    .font(.system(.subheadline, design: .default, weight: .bold))
                    .foregroundStyle(scoreColor)
                XPBadge(xp: result.xpEarned)
            }
        }
        .padding(.horizontal, FluencyTheme.cardPadding)
        .padding(.vertical, 10)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.03), radius: 3, y: 1)
    }
}
