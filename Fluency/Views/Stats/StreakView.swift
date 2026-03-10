import SwiftUI
import SwiftData

/// Streak calendar screen — accessible from Home streak card
/// Shows month grid, current streak, all-time stats, and Streak Shield (premium)
struct StreakView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \LessonResult.completedAt) private var results: [LessonResult]
    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var shieldEnabled = false

    private var calendar: Calendar { Calendar.current }

    // MARK: - Computed

    private var completedDates: Set<String> {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return Set(results.compactMap { $0.completedAt }.map { formatter.string(from: $0) })
    }

    private var monthDays: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            days.append(calendar.date(byAdding: .day, value: day - 1, to: firstDay))
        }
        // Pad to complete last row
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var canGoForward: Bool {
        displayedMonth < calendar.startOfMonth(for: Date())
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                FluencyTheme.surface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {

                        // Current streak hero
                        streakHero

                        // Calendar
                        calendarCard

                        // All-time stats
                        allTimeStats

                        // Streak Shield (premium)
                        streakShield

                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Your Streak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(FluencyTheme.primary)
                }
            }
        }
    }

    // MARK: - Streak Hero

    private var streakHero: some View {
        VStack(spacing: 12) {
            HStack(alignment: .bottom, spacing: 8) {
                Text("\(user.currentStreak)")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(FluencyTheme.primary)
                Text("days")
                    .font(.system(.title2, design: .default, weight: .semibold))
                    .foregroundStyle(FluencyTheme.textSecondary)
                    .padding(.bottom, 12)
            }

            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Current Streak")
                    .font(FluencyTheme.bodyMedium)
                    .foregroundStyle(FluencyTheme.textSecondary)
            }

            if user.currentStreak > 0 {
                Text("Keep it going")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(FluencyTheme.primary.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius + 4))
        .shadow(color: FluencyTheme.primary.opacity(0.08), radius: 12, y: 4)
    }

    // MARK: - Calendar

    private var calendarCard: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button {
                    withAnimation(FluencyTheme.springSnappy) {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(FluencyTheme.primary)
                }

                Spacer()
                Text(monthTitle)
                    .font(.system(.headline, design: .default, weight: .bold))
                Spacer()

                Button {
                    guard canGoForward else { return }
                    withAnimation(FluencyTheme.springSnappy) {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(canGoForward ? FluencyTheme.primary : FluencyTheme.border)
                }
                .disabled(!canGoForward)
            }

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["S","M","T","W","T","F","S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(FluencyTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            let rows = monthDays.chunked(into: 7)
            VStack(spacing: 6) {
                ForEach(rows.indices, id: \.self) { rowIdx in
                    HStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { col in
                            let idx = rowIdx * 7 + col
                            if idx < monthDays.count, let date = monthDays[idx] {
                                CalendarDayCell(date: date, completedDates: completedDates)
                            } else {
                                Color.clear.frame(maxWidth: .infinity).frame(height: 36)
                            }
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 16) {
                LegendItem(color: FluencyTheme.success, label: "Completed")
                LegendItem(color: FluencyTheme.primary.opacity(0.2), label: "Today")
                LegendItem(color: FluencyTheme.border, label: "Missed")
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(FluencyTheme.cardPadding)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - All-time Stats

    private var allTimeStats: some View {
        HStack(spacing: 0) {
            StatTile(value: "\(user.longestStreak)", label: "Longest Streak", icon: "flame.fill", color: .orange)
            Divider().frame(height: 50)
            StatTile(value: "\(completedDates.count)", label: "Total Days", icon: "calendar.badge.checkmark", color: FluencyTheme.success)
            Divider().frame(height: 50)
            StatTile(value: "\(user.totalXP)", label: "Total XP", icon: "star.fill", color: FluencyTheme.gold)
        }
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    // MARK: - Streak Shield (premium)

    private var streakShield: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "shield.fill")
                    .font(.title3)
                    .foregroundStyle(FluencyTheme.primary)
                Text("Streak Shield")
                    .font(.system(.headline, design: .default, weight: .bold))
                Spacer()
                if !user.isPremium {
                    Text("PRO")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(FluencyTheme.heroGradient)
                        .clipShape(Capsule())
                }
            }

            Text("Protect your streak during travel or busy days. Shield activates automatically when you miss a day.")
                .font(FluencyTheme.captionFont)
                .foregroundStyle(FluencyTheme.textSecondary)

            if user.isPremium {
                Toggle("Enable Streak Shield", isOn: $shieldEnabled)
                    .tint(FluencyTheme.primary)
            } else {
                FluencyPrimaryButton("Unlock with Pro") {
                    // navigate to paywall
                }
            }
        }
        .padding(FluencyTheme.cardPadding)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

// MARK: - Calendar Day Cell

private struct CalendarDayCell: View {
    let date: Date
    let completedDates: Set<String>

    private var calendar: Calendar { Calendar.current }
    private var formatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    private var dayNumber: Int { calendar.component(.day, from: date) }
    private var isToday: Bool { calendar.isDateInToday(date) }
    private var isFuture: Bool { date > Date() }
    private var isCompleted: Bool { completedDates.contains(formatter.string(from: date)) }

    private var bgColor: Color {
        if isCompleted { return FluencyTheme.success }
        if isToday { return FluencyTheme.primary.opacity(0.15) }
        return Color.clear
    }

    private var textColor: Color {
        if isCompleted { return .white }
        if isToday { return FluencyTheme.primary }
        if isFuture { return FluencyTheme.textDisabled }
        return FluencyTheme.textSecondary
    }

    var body: some View {
        Text("\(dayNumber)")
            .font(.system(size: 14, weight: isToday || isCompleted ? .bold : .regular))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(bgColor)
            .clipShape(Circle())
            .overlay {
                if isToday && !isCompleted {
                    Circle().stroke(FluencyTheme.primary, lineWidth: 2)
                }
            }
    }
}

// MARK: - Helpers

private struct LegendItem: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(FluencyTheme.captionFont).foregroundStyle(FluencyTheme.textSecondary)
        }
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.body).foregroundStyle(color)
            Text(value).font(.system(.headline, design: .default, weight: .bold))
            Text(label).font(.system(size: 11)).foregroundStyle(FluencyTheme.textSecondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}

// MARK: - Calendar extensions

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
