import SwiftUI

struct LearnView: View {
    let user: User
    @State private var course: CourseContent?

    var body: some View {
        NavigationStack {
            Group {
                if let course = course {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(course.units.sorted(by: { $0.order < $1.order })) { unit in
                                UnitCard(unit: unit, user: user)
                            }
                        }
                        .padding()
                    }
                    .background(FluencyTheme.surface.ignoresSafeArea())
                } else {
                    ProgressView("Loading Spanish course...")
                }
            }
            .navigationTitle("Learn Spanish 🇪🇸")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            course = ContentLoader.shared.loadSpanishCourse()
        }
    }
}

// MARK: - Unit Card

struct UnitCard: View {
    let unit: UnitContent
    let user: User

    private var completedCount: Int {
        unit.lessons.filter { lesson in
            user.progress.contains { $0.lessonId == lesson.id && $0.isCompleted }
        }.count
    }

    private var unitProgress: Double {
        guard !unit.lessons.isEmpty else { return 0 }
        return Double(completedCount) / Double(unit.lessons.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Unit header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: unit.color).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text(unitEmoji(unit.icon))
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(unit.name)
                        .font(FluencyTheme.headlineFont)
                    Text("\(completedCount)/\(unit.lessons.count) lessons complete")
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(FluencyTheme.textSecondary)
                }
                Spacer()

                // Progress circle
                ZStack {
                    Circle()
                        .stroke(FluencyTheme.border, lineWidth: 3)
                        .frame(width: 36, height: 36)
                    Circle()
                        .trim(from: 0, to: unitProgress)
                        .stroke(FluencyTheme.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.5), value: unitProgress)
                }
            }
            .padding(FluencyTheme.cardPadding)

            Divider().padding(.horizontal)

            // Lesson list
            ForEach(unit.lessons.sorted(by: { $0.order < $1.order })) { lessonRef in
                LessonRow(lessonRef: lessonRef, user: user)
                if lessonRef.id != unit.lessons.last?.id {
                    Divider().padding(.leading, 52)
                }
            }
        }
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func unitEmoji(_ icon: String) -> String {
        switch icon {
        case "wave": return "👋"
        case "restaurant": return "🍽️"
        case "family": return "👨‍👩‍👧"
        case "calculator": return "🔢"
        case "location_on": return "📍"
        case "directions_bus": return "🚌"
        case "palette": return "🎨"
        case "pets": return "🐾"
        case "shopping_cart": return "🛒"
        case "wb_sunny": return "☀️"
        default: return "📚"
        }
    }
}

// MARK: - Lesson Row

struct LessonRow: View {
    let lessonRef: LessonRef
    let user: User

    @State private var lessonContent: LessonContent?
    @State private var showLesson = false

    private var isCompleted: Bool {
        user.progress.contains { $0.lessonId == lessonRef.id && $0.isCompleted }
    }

    private var isLocked: Bool {
        // First lesson always unlocked; others unlock sequentially
        lessonRef.order > 1 && !isCompleted && !previousLessonCompleted
    }

    private var previousLessonCompleted: Bool {
        // Simplified: assume order-1 lesson in same unit is complete
        user.progress.contains { $0.lessonId == lessonRef.id }
    }

    var body: some View {
        Button {
            if !isLocked {
                lessonContent = ContentLoader.shared.loadLesson(id: lessonRef.id)
                if lessonContent != nil { showLesson = true }
            }
        } label: {
            HStack(spacing: 12) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(isCompleted ? FluencyTheme.primary : (isLocked ? FluencyTheme.border : FluencyTheme.primary.opacity(0.15)))
                        .frame(width: 36, height: 36)
                    Image(systemName: isCompleted ? "checkmark" : (isLocked ? "lock.fill" : "play.fill"))
                        .font(.caption)
                        .foregroundStyle(isCompleted ? .white : (isLocked ? FluencyTheme.textSecondary : FluencyTheme.primary))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(lessonRef.name)
                        .font(FluencyTheme.bodyFont)
                        .foregroundStyle(isLocked ? FluencyTheme.textSecondary : FluencyTheme.textPrimary)
                    Text(lessonRef.description)
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(FluencyTheme.textSecondary)
                }

                Spacer()

                Text("+\(lessonRef.xpReward) XP")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.gold)
                    .opacity(isLocked ? 0.4 : 1)
            }
            .padding(.horizontal, FluencyTheme.cardPadding)
            .padding(.vertical, 12)
        }
        .fullScreenCover(item: $lessonContent) { lesson in
            LessonIntroView(lesson: lesson, user: user)
        }
    }
}


