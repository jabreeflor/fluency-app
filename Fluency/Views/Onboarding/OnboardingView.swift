import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var step: Int = 0
    @State private var username: String = ""
    @State private var selectedGoal: Int = 20

    private let goals = [10, 20, 30, 50]

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? FluencyTheme.primary : FluencyTheme.border)
                        .frame(width: i == step ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: step)
                }
            }
            .padding(.top, 24)

            Spacer()

            // Step content
            switch step {
            case 0: welcomeStep
            case 1: nameStep
            case 2: goalStep
            default: welcomeStep
            }

            Spacer()

            // CTA
            Button(step < 2 ? "Continue" : "Start Learning 🚀") {
                if step < 2 {
                    withAnimation { step += 1 }
                } else {
                    createUser()
                }
            }
            .buttonStyle(FluencyButtonStyle(isDisabled: step == 1 && username.isEmpty))
            .disabled(step == 1 && username.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(FluencyTheme.surface.ignoresSafeArea())
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Text("🇪🇸")
                .font(.system(size: 80))
            Text("Learn Spanish\nfor free")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
            Text("Bite-sized lessons. Daily streaks.\nActually fun.")
                .font(FluencyTheme.bodyFont)
                .foregroundStyle(FluencyTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var nameStep: some View {
        VStack(spacing: 24) {
            Text("What's your name?")
                .font(FluencyTheme.titleFont)
            TextField("Your name", text: $username)
                .font(.title3)
                .padding(FluencyTheme.cardPadding)
                .background(FluencyTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
                .overlay(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius).stroke(FluencyTheme.border, lineWidth: 2))
                .padding(.horizontal, 24)
                .autocorrectionDisabled()
        }
    }

    private var goalStep: some View {
        VStack(spacing: 24) {
            Text("Set your daily goal")
                .font(FluencyTheme.titleFont)
            Text("How much time do you want to spend learning each day?")
                .font(FluencyTheme.bodyFont)
                .foregroundStyle(FluencyTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(goals, id: \.self) { goal in
                    Button {
                        withAnimation { selectedGoal = goal }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(goal) XP per day")
                                    .font(FluencyTheme.headlineFont)
                                Text(goalDescription(goal))
                                    .font(FluencyTheme.captionFont)
                                    .foregroundStyle(FluencyTheme.textSecondary)
                            }
                            Spacer()
                            if selectedGoal == goal {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(FluencyTheme.primary)
                                    .font(.title2)
                            }
                        }
                        .padding(FluencyTheme.cardPadding)
                        .background(selectedGoal == goal ? FluencyTheme.primary.opacity(0.08) : FluencyTheme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius)
                                .stroke(selectedGoal == goal ? FluencyTheme.primary : FluencyTheme.border, lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func goalDescription(_ xp: Int) -> String {
        switch xp {
        case 10: return "Casual · ~5 min/day"
        case 20: return "Regular · ~10 min/day"
        case 30: return "Serious · ~15 min/day"
        case 50: return "Intense · ~25 min/day"
        default: return ""
        }
    }

    // MARK: - Create User

    private func createUser() {
        let user = User(username: username.isEmpty ? "Learner" : username)
        user.dailyXPGoal = selectedGoal
        modelContext.insert(user)

        // Seed achievements
        for type in AchievementType.allCases {
            let achievement = UserAchievement(userId: user.id, type: type)
            modelContext.insert(achievement)
            achievement.user = user
        }

        try? modelContext.save()
    }
}
