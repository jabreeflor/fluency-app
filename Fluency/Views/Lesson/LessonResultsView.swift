import SwiftUI
import UIKit

/// Full-screen results screen with XP animation shown after completing a lesson
struct LessonResultsView: View {
    let score: Double
    let xpEarned: Int
    let correctAnswers: Int
    let totalQuestions: Int
    let streak: Int
    /// Total number of lessons the user has completed across all sessions
    var totalLessonsCompleted: Int = 0
    let onContinue: () -> Void

    @Environment(\.openURL) private var openURL

    @State private var showXP = false
    @State private var showStats = false
    @State private var xpAnimated: Int = 0
    @State private var showConfetti = false

    private var isPerfect: Bool { score >= 1.0 }
    private var isGood: Bool { score >= 0.8 }

    var body: some View {
        ZStack {
            FluencyTheme.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Trophy / emoji
                Text(isPerfect ? "🏆" : isGood ? "🎉" : "👍")
                    .font(.system(size: 90))
                    .scaleEffect(showXP ? 1.0 : 0.3)
                    .opacity(showXP ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: showXP)

                Spacer().frame(height: 24)

                // Title
                Text(isPerfect ? "Perfect!" : isGood ? "Lesson Complete!" : "Good Effort!")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .opacity(showXP ? 1 : 0)
                    .offset(y: showXP ? 0 : 20)
                    .animation(.spring(response: 0.5).delay(0.2), value: showXP)

                Spacer().frame(height: 8)

                Text("\(Int(score * 100))% correct")
                    .font(FluencyTheme.bodyFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
                    .opacity(showXP ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.3), value: showXP)

                Spacer().frame(height: 32)

                // XP Badge with count-up animation
                HStack(spacing: 10) {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundStyle(FluencyTheme.gold)
                    Text("+\(xpAnimated) XP")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(FluencyTheme.gold)
                        .contentTransition(.numericText())
                        .animation(.easeOut(duration: 1.2).delay(0.5), value: xpAnimated)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(FluencyTheme.gold.opacity(0.15))
                .clipShape(Capsule())
                .scaleEffect(showXP ? 1.0 : 0.7)
                .opacity(showXP ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: showXP)

                Spacer().frame(height: 32)

                // Stats row
                if showStats {
                    HStack(spacing: 0) {
                        StatBadge(label: "Correct", value: "\(correctAnswers)/\(totalQuestions)", icon: "checkmark.circle.fill", color: FluencyTheme.primary)
                        Divider().frame(height: 40)
                        StatBadge(label: "Accuracy", value: "\(Int(score * 100))%", icon: "target", color: .blue)
                        Divider().frame(height: 40)
                        StatBadge(label: "Streak", value: "\(streak)", icon: "flame.fill", color: .orange)
                    }
                    .background(FluencyTheme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                // Continue button
                Button("Continue", action: onContinue)
                    .buttonStyle(FluencyButtonStyle())
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                    .opacity(showStats ? 1 : 0)
                    .offset(y: showStats ? 0 : 20)
                    .animation(.spring(response: 0.4).delay(0.1), value: showStats)
            }
        }
        .onAppear {
            animate()
            // Fire review prompt after animation settles (≥1s delay keeps it off mid-lesson)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                let scene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
                ReviewPromptManager.shared.evaluate(
                    totalLessonsCompleted: totalLessonsCompleted,
                    currentStreak: streak,
                    accuracy: score,
                    scene: scene
                )
            }
        }
    }

    private func animate() {
        // Step 1: show trophy + title
        withAnimation { showXP = true }

        // Step 2: count up XP
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation { xpAnimated = xpEarned }
        }

        // Step 3: show stats
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.5)) { showStats = true }
        }
    }
}

struct StatBadge: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(FluencyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
