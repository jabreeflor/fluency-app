import SwiftUI
import SwiftData

// MARK: - Onboarding Flow (6 screens per Ellis spec)

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var step = 0
    @State private var selectedGoal: String?
    @State private var selectedLevel: String?
    @State private var selectedMinutes: Int = 10
    @State private var showPaywall = false
    @State private var showAccount = false

    var body: some View {
        ZStack {
            // Slide transition between steps
            switch step {
            case 0: SplashScreen(onStart: { withAnimation { step = 1 } },
                                  onLogin: { createUserAndFinish() })
            case 1: GoalSelectionScreen(selected: $selectedGoal,
                                         onNext: { withAnimation { step = 2 } })
            case 2: LevelScreen(selected: $selectedLevel,
                                onNext: { withAnimation { step = 3 } })
            case 3: CommitmentScreen(selectedMinutes: $selectedMinutes,
                                     onNext: { withAnimation { step = 4 } })
            case 4: OnboardingPaywall(onTrial: { withAnimation { step = 5 } },
                                      onFree: { withAnimation { step = 5 } })
            case 5: AccountCreationScreen(onCreate: { createUserAndFinish() })
            default: EmptyView()
            }
        }
        .animation(FluencyTheme.springSnappy, value: step)
    }

    private func createUserAndFinish() {
        let user = User()
        user.dailyXPGoal = selectedMinutes * 2 // ~2 XP/min
        modelContext.insert(user)
        try? modelContext.save()
    }
}

// MARK: - Screen 1.1 — Splash / Hero

private struct SplashScreen: View {
    let onStart: () -> Void
    let onLogin: () -> Void

    var body: some View {
        ZStack {
            FluencyTheme.heroGradientVertical.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 16) {
                    Text("Fluency")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Spanish that sticks.")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                VStack(spacing: 14) {
                    Button("Get Started", action: onStart)
                        .font(.system(.body, design: .default, weight: .semibold))
                        .foregroundStyle(FluencyTheme.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: FluencyTheme.buttonHeight)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .padding(.horizontal, 24)

                    Button("I already have an account", action: onLogin)
                        .font(.system(.subheadline, design: .default, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Screen 1.2 — Goal Selection

private struct GoalSelectionScreen: View {
    @Binding var selected: String?
    let onNext: () -> Void

    private let goals: [(icon: String, label: String)] = [
        ("✈️", "Travel"),
        ("💼", "Work"),
        ("❤️", "Family / Friends"),
        ("🧠", "Personal Growth")
    ]

    var body: some View {
        OnboardingShell(title: "Why are you learning Spanish?", step: 1, total: 4) {
            VStack(spacing: 12) {
                ForEach(goals, id: \.label) { goal in
                    ChoiceCard(icon: goal.icon, label: goal.label, isSelected: selected == goal.label) {
                        selected = goal.label
                    }
                }
            }
        } footer: {
            FluencyPrimaryButton("Next", isDisabled: selected == nil, action: onNext)
                .padding(.horizontal)
        }
    }
}

// MARK: - Screen 1.3 — Level Assessment

private struct LevelScreen: View {
    @Binding var selected: String?
    let onNext: () -> Void

    private let levels: [(icon: String, label: String)] = [
        ("🌱", "Complete beginner"),
        ("📖", "Know some basics"),
        ("💬", "Intermediate — can have simple conversations"),
        ("🎯", "Advanced — want to polish")
    ]

    var body: some View {
        OnboardingShell(title: "How much Spanish do you know?", step: 2, total: 4) {
            VStack(spacing: 12) {
                ForEach(levels, id: \.label) { level in
                    ChoiceCard(icon: level.icon, label: level.label, isSelected: selected == level.label) {
                        selected = level.label
                    }
                }
            }
        } footer: {
            FluencyPrimaryButton("Next", isDisabled: selected == nil, action: onNext)
                .padding(.horizontal)
        }
    }
}

// MARK: - Screen 1.4 — Commitment

private struct CommitmentScreen: View {
    @Binding var selectedMinutes: Int
    let onNext: () -> Void

    private let options = [5, 10, 15]

    var body: some View {
        OnboardingShell(title: "How much time per day?", step: 3, total: 4) {
            HStack(spacing: 14) {
                ForEach(options, id: \.self) { mins in
                    CommitmentCard(
                        minutes: mins,
                        isSelected: selectedMinutes == mins,
                        action: { selectedMinutes = mins }
                    )
                }
            }
        } footer: {
            FluencyPrimaryButton("Next", action: onNext)
                .padding(.horizontal)
        }
    }
}

private struct CommitmentCard: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(minutes == 15 ? "15+" : "\(minutes)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(isSelected ? .white : FluencyTheme.primary)
                Text("min / day")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : FluencyTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? FluencyTheme.primary : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius)
                .stroke(isSelected ? FluencyTheme.primary : FluencyTheme.border, lineWidth: isSelected ? 0 : 1))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .animation(FluencyTheme.springSnappy, value: isSelected)
    }
}

// MARK: - Screen 1.5 — Paywall

private struct OnboardingPaywall: View {
    let onTrial: () -> Void
    let onFree: () -> Void
    @State private var isAnnual = true

    private let features = [
        "Unlimited lessons and practice",
        "Pronunciation coaching",
        "No streak pressure — your schedule"
    ]

    var body: some View {
        ZStack {
            FluencyTheme.surface.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                // Hero
                VStack(spacing: 10) {
                    Text("Start your 7-day\nfree trial")
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)
                    Text("No credit card required")
                        .font(FluencyTheme.bodyFont)
                        .foregroundStyle(FluencyTheme.textSecondary)
                }

                Spacer().frame(height: 32)

                // Features
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(FluencyTheme.success)
                                .font(.title3)
                            Text(feature)
                                .font(FluencyTheme.bodyFont)
                        }
                    }
                }
                .padding(FluencyTheme.cardPadding)
                .background(FluencyTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                .padding(.horizontal)

                Spacer().frame(height: 28)

                // Price toggle
                HStack(spacing: 2) {
                    PriceToggleButton(label: "Monthly\n$9.99", isSelected: !isAnnual) { isAnnual = false }
                    PriceToggleButton(label: "Annual\n$49.99", badge: "Most Popular", isSelected: isAnnual) { isAnnual = true }
                }
                .padding(.horizontal)

                Spacer().frame(height: 24)

                VStack(spacing: 10) {
                    FluencyPrimaryButton("Try Free for 7 Days", action: onTrial)
                        .padding(.horizontal)

                    Button("Continue with free version", action: onFree)
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(FluencyTheme.textSecondary)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

private struct PriceToggleButton: View {
    let label: String
    var badge: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 4) {
                    Text(label)
                        .font(.system(.subheadline, design: .default, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : FluencyTheme.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSelected ? FluencyTheme.primary : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? FluencyTheme.primary : FluencyTheme.border, lineWidth: 1))

                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(FluencyTheme.gold)
                        .clipShape(Capsule())
                        .offset(x: -4, y: -6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Screen 1.6 — Account Creation

private struct AccountCreationScreen: View {
    let onCreate: () -> Void
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        OnboardingShell(title: "Create your account", step: 4, total: 4) {
            VStack(spacing: 16) {
                // Sign in with Apple (prominent)
                Button {
                    onCreate() // stub — real auth in future
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "applelogo")
                            .font(.body)
                        Text("Sign up with Apple")
                            .font(.system(.body, design: .default, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: FluencyTheme.buttonHeight)
                    .background(Color.black)
                    .clipShape(Capsule())
                }

                Button {
                    onCreate() // stub
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "globe")
                            .font(.body)
                        Text("Sign up with Google")
                            .font(.system(.body, design: .default, weight: .semibold))
                    }
                    .foregroundStyle(FluencyTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: FluencyTheme.buttonHeight)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(FluencyTheme.border, lineWidth: 1))
                }

                HStack {
                    VStack { Divider() }
                    Text("or")
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(FluencyTheme.textSecondary)
                        .padding(.horizontal, 8)
                    VStack { Divider() }
                }

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding(FluencyTheme.cardPadding)
                        .background(FluencyTheme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
                        .overlay(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius).stroke(FluencyTheme.border))

                    SecureField("Password", text: $password)
                        .padding(FluencyTheme.cardPadding)
                        .background(FluencyTheme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
                        .overlay(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius).stroke(FluencyTheme.border))
                }
            }
        } footer: {
            FluencyPrimaryButton("Create Account",
                                 isDisabled: email.isEmpty || password.count < 6,
                                 action: onCreate)
                .padding(.horizontal)
        }
    }
}

// MARK: - Shared Shell

private struct OnboardingShell<Content: View, Footer: View>: View {
    let title: String
    let step: Int
    let total: Int
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    var body: some View {
        ZStack {
            FluencyTheme.surface.ignoresSafeArea()
            VStack(spacing: 0) {
                // Step indicator dots
                HStack(spacing: 6) {
                    ForEach(1...total, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? FluencyTheme.primary : FluencyTheme.border)
                            .frame(width: i == step ? 20 : 8, height: 8)
                            .animation(FluencyTheme.springSnappy, value: step)
                    }
                }
                .padding(.top, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(title)
                            .font(.system(size: 28, weight: .bold))
                            .padding(.top, 24)
                        content
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }

                footer
                    .padding(.bottom, 32)
            }
        }
    }
}
