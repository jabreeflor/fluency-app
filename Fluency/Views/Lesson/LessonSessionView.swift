import SwiftUI

struct LessonSessionView: View {
    let lesson: LessonContent
    let user: User

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var session: LessonSession

    init(lesson: LessonContent, user: User) {
        self.lesson = lesson
        self.user = user
        // Temporary context — will be overridden in onAppear via restartWithContext
        _session = StateObject(wrappedValue: LessonSession.placeholder(user: user))
    }

    var body: some View {
        ZStack {
            FluencyTheme.surface.ignoresSafeArea()

            switch session.sessionState {
            case .idle:
                ProgressView("Loading lesson...")
                    .onAppear {
                        session.configure(context: modelContext)
                        session.start(lesson: lesson)
                    }

            case .active, .showingFeedback:
                activeSessionView

            case .complete(let score, let xp, let correct, let total):
                LessonResultsView(
                    score: score,
                    xpEarned: xp,
                    correctAnswers: correct,
                    totalQuestions: total,
                    streak: user.currentStreak,
                    onContinue: { dismiss() }
                )

            case .failed:
                LessonFailedView(lesson: lesson) {
                    dismiss()
                } onRetry: {
                    session.start(lesson: lesson)
                }
            }
        }
        .interactiveDismissDisabled(true)
    }

    @ViewBuilder
    private var activeSessionView: some View {
        VStack(spacing: 0) {
            LessonTopBar(
                progress: session.progressFraction,
                hearts: session.hearts,
                onClose: { dismiss() }
            )

            if let exercise = session.currentExercise {
                ScrollView {
                    VStack(spacing: 24) {
                        Text(exercise.exerciseType.instruction.uppercased())
                            .font(FluencyTheme.captionFont)
                            .foregroundStyle(FluencyTheme.textSecondary)
                            .tracking(1.5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 24)

                        exerciseView(for: exercise)
                            .padding(.horizontal)

                        if let hint = exercise.hint {
                            if !session.showHint {
                                Button {
                                    session.requestHint()
                                } label: {
                                    Label("Show hint", systemImage: "lightbulb")
                                        .font(FluencyTheme.captionFont)
                                        .foregroundStyle(FluencyTheme.primary)
                                }
                            } else {
                                Text(hint)
                                    .font(FluencyTheme.captionFont)
                                    .foregroundStyle(FluencyTheme.textSecondary)
                                    .padding(8)
                                    .background(FluencyTheme.primary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }

            Spacer()

            if case .showingFeedback(let correct) = session.sessionState {
                FeedbackBar(isCorrect: correct, correctAnswer: session.currentExercise?.correctAnswer ?? "")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: session.sessionState.isFeedback)
    }

    @ViewBuilder
    private func exerciseView(for exercise: ExerciseContent) -> some View {
        switch exercise.exerciseType {
        case .multipleChoice:
            MultipleChoiceView(exercise: exercise, session: session)
        case .fillBlank, .translation:
            FillBlankView(exercise: exercise, session: session)
        case .wordBank:
            WordBankView(exercise: exercise, session: session)
        case .listening:
            ListeningView(exercise: exercise, session: session)
        case .speaking:
            SpeakingView(exercise: exercise, session: session)
        case .matching:
            MultipleChoiceView(exercise: exercise, session: session)
        }
    }
}

// MARK: - Top Bar

struct LessonTopBar: View {
    let progress: Double
    let hearts: Int
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(FluencyTheme.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8).fill(FluencyTheme.border).frame(height: 16)
                    RoundedRectangle(cornerRadius: 8).fill(FluencyTheme.primary)
                        .frame(width: max(0, geo.size.width * progress), height: 16)
                        .animation(.spring(response: 0.4), value: progress)
                }
            }
            .frame(height: 16)

            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { i in
                    Text(i < hearts ? "❤️" : "🖤")
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(FluencyTheme.surface)
    }
}

// MARK: - Feedback Bar

struct FeedbackBar: View {
    let isCorrect: Bool
    let correctAnswer: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isCorrect ? FluencyTheme.primary : FluencyTheme.accent)
                    .font(.title2)
                Text(isCorrect ? "Correct!" : "Incorrect")
                    .font(FluencyTheme.headlineFont)
                    .foregroundStyle(isCorrect ? FluencyTheme.primary : FluencyTheme.accent)
                Spacer()
            }
            if !isCorrect {
                HStack {
                    Text("Correct answer:")
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(FluencyTheme.textSecondary)
                    Text(correctAnswer)
                        .font(FluencyTheme.bodyFont)
                        .bold()
                        .foregroundStyle(FluencyTheme.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(FluencyTheme.cardPadding)
        .background(isCorrect ? FluencyTheme.correctGreen : FluencyTheme.wrongRed)
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundStyle(isCorrect ? FluencyTheme.correctBorder : FluencyTheme.wrongBorder),
            alignment: .top
        )
    }
}

// MARK: - Result / Failed Views

struct LessonResultView: View {
    let score: Double
    let xpEarned: Int
    let lesson: LessonContent
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text(score >= 0.8 ? "🎉" : "👍")
                .font(.system(size: 80))
            Text(score >= 0.8 ? "Lesson Complete!" : "Good Effort!")
                .font(FluencyTheme.titleFont)
            Text("You got \(Int(score * 100))% correct")
                .font(FluencyTheme.bodyFont)
                .foregroundStyle(FluencyTheme.textSecondary)

            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundStyle(FluencyTheme.gold)
                Text("+\(xpEarned) XP")
                    .font(FluencyTheme.headlineFont)
                    .foregroundStyle(FluencyTheme.gold)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(FluencyTheme.gold.opacity(0.15))
            .clipShape(Capsule())

            Spacer()

            Button("Continue", action: onContinue)
                .buttonStyle(FluencyButtonStyle())
                .padding(.horizontal)
        }
        .padding()
    }
}

struct LessonFailedView: View {
    let lesson: LessonContent
    let onQuit: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("💔").font(.system(size: 80))
            Text("Out of Hearts!").font(FluencyTheme.titleFont)
            Text("You ran out of lives. Try again!")
                .font(FluencyTheme.bodyFont)
                .foregroundStyle(FluencyTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            VStack(spacing: 12) {
                Button("Try Again", action: onRetry)
                    .buttonStyle(FluencyButtonStyle())
                Button("Quit", action: onQuit)
                    .buttonStyle(FluencyOutlineButtonStyle(color: FluencyTheme.textSecondary))
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - SessionState helpers

extension SessionState: Equatable {
    static func == (lhs: SessionState, rhs: SessionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.active, .active), (.failed, .failed): return true
        case (.showingFeedback(let a), .showingFeedback(let b)): return a == b
        case (.complete(let s1, let x1, _, _), .complete(let s2, let x2, _, _)): return s1 == s2 && x1 == x2
        default: return false
        }
    }

    var isFeedback: Bool {
        if case .showingFeedback = self { return true }
        return false
    }
}
