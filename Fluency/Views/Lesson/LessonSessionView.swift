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
                failedView
            }
        }
        .interactiveDismissDisabled(true)
    }

    // MARK: - Active Session View

    @ViewBuilder
    private var activeSessionView: some View {
        VStack(spacing: 0) {
            // Top bar: progress + hearts
            LessonTopBar(
                progress: session.progressFraction,
                hearts: session.hearts,
                onClose: { dismiss() }
            )

            if let exercise = session.currentExercise {
                ScrollView {
                    VStack(spacing: 24) {
                        // Exercise type label
                        Text(exercise.exerciseType.instruction.uppercased())
                            .font(FluencyTheme.captionFont)
                            .foregroundStyle(FluencyTheme.textSecondary)
                            .tracking(1.5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)

                        exerciseView(for: exercise)
                            .padding(.horizontal, 20)

                        // Hint
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
                                    .padding(10)
                                    .background(FluencyTheme.primary.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }

            Spacer()

            // Bottom area: feedback bar or check button
            if case .showingFeedback(let correct) = session.sessionState {
                FeedbackBar(
                    isCorrect: correct,
                    correctAnswer: session.currentExercise?.correctAnswer ?? "",
                    nativeNote: correct ? session.currentExercise?.hint : nil,
                    onContinue: { session.advanceExercise() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                // Check button — grey until the session has a pending answer
                FluencyPrimaryButton(
                    "Check",
                    isDisabled: !session.hasAnswer,
                    action: { session.checkCurrentAnswer() }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .animation(FluencyTheme.slideUp, value: session.sessionState.isFeedback)
    }

    // MARK: - Exercise routing

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

    // MARK: - Failed View

    private var failedView: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("💔").font(.system(size: 80))
            Text("Out of Hearts!")
                .font(.system(.title, design: .default, weight: .bold))
            Text("You ran out of lives. Try again or wait for hearts to refill.")
                .font(FluencyTheme.bodyFont)
                .foregroundStyle(FluencyTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            VStack(spacing: 12) {
                FluencyPrimaryButton("Try Again") { session.start(lesson: lesson) }
                    .padding(.horizontal)
                FluencySecondaryButton(label: "Quit") { dismiss() }
                    .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Top Bar

struct LessonTopBar: View {
    let progress: Double
    let hearts: Int
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(FluencyTheme.textSecondary)
            }

            FluencyProgressBar(progress: progress)

            HStack(spacing: 2) {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(FluencyTheme.error)
                Text("\(hearts)")
                    .font(.system(.caption, design: .default, weight: .bold))
                    .foregroundStyle(FluencyTheme.textPrimary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(FluencyTheme.surface)
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
