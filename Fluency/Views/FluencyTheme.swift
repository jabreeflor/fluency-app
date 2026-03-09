import SwiftUI

// MARK: - Design System
// Ellis Design Spec v1 — 2026-03-09
// Calm confidence. Linear × Calm × Apple native.

enum FluencyTheme {

    // MARK: - Color Palette

    /// Primary action, CTA buttons, progress bars
    static let primary = Color(hex: "#2D5BE3")
    /// Violet — gradient pair with primary
    static let violet = Color(hex: "#6B2DEF")
    /// Hero gradient (onboarding splash, paywall)
    static let heroGradient = LinearGradient(
        colors: [Color(hex: "#2D5BE3"), Color(hex: "#6B2DEF")],
        startPoint: .leading, endPoint: .trailing
    )
    static let heroGradientVertical = LinearGradient(
        colors: [Color(hex: "#2D5BE3"), Color(hex: "#6B2DEF")],
        startPoint: .top, endPoint: .bottom
    )

    /// Correct answer, success states, streak
    static let success = Color(hex: "#4ECCA3")
    /// Incorrect answer, error states
    static let error = Color(hex: "#FF6B6B")
    /// XP / achievement highlights
    static let gold = Color(hex: "#FFD93D")

    /// Light mode background
    static let surface = Color(hex: "#F7F8FF")
    /// Dark mode background / premium feel
    static let deepNavy = Color(hex: "#1A1A2E")
    /// Pure white card surfaces
    static let cardBg = Color.white
    /// Border / divider
    static let border = Color(hex: "#E5E8F0")

    static let textPrimary = Color.primary
    static let textSecondary = Color(hex: "#7A7A9A")
    static let textDisabled = Color(hex: "#B0B3C6")

    // MARK: - Typography

    /// Display/Hero — SF Pro Display Bold 34-40pt
    static func displayFont(size: CGFloat = 34) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }
    /// Screen titles, big numbers
    static let heroFont = Font.system(.largeTitle, design: .default, weight: .bold)
    /// Body/Primary — SF Pro Text Regular/Medium 17pt
    static let bodyFont = Font.system(.body, design: .default, weight: .regular)
    static let bodyMedium = Font.system(.body, design: .default, weight: .medium)
    /// Caption/Secondary — SF Pro Text Regular 13pt
    static let captionFont = Font.system(.caption, design: .default, weight: .regular)

    // MARK: - Layout

    static let cornerRadius: CGFloat = 12
    static let buttonHeight: CGFloat = 56
    static let cardPadding: CGFloat = 16

    // MARK: - Animations

    static let springSnappy = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let slideUp = Animation.spring(response: 0.4, dampingFraction: 0.75)
}

// MARK: - Color Hex Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 3:
            (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6:
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Reusable Components

/// Primary button — blue filled pill, full width, 56pt
struct FluencyPrimaryButton: View {
    let label: String
    let isDisabled: Bool
    let action: () -> Void

    init(_ label: String, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(.body, design: .default, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: FluencyTheme.buttonHeight)
                .background(isDisabled ? FluencyTheme.textDisabled : FluencyTheme.primary)
                .clipShape(Capsule())
        }
        .disabled(isDisabled)
    }
}

/// Secondary button — white outlined pill
struct FluencySecondaryButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(.body, design: .default, weight: .semibold))
                .foregroundStyle(FluencyTheme.primary)
                .frame(maxWidth: .infinity)
                .frame(height: FluencyTheme.buttonHeight)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(FluencyTheme.primary, lineWidth: 2))
        }
    }
}

/// Choice card — rounded rect, white bg, subtle shadow, 12pt radius
struct ChoiceCard: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(icon)
                    .font(.title2)
                Text(label)
                    .font(FluencyTheme.bodyMedium)
                    .foregroundStyle(isSelected ? FluencyTheme.primary : FluencyTheme.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(FluencyTheme.primary)
                }
            }
            .padding(FluencyTheme.cardPadding)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius)
                    .stroke(isSelected ? FluencyTheme.primary : FluencyTheme.border, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

/// XP badge — yellow pill with star + number
struct XPBadge: View {
    let xp: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundStyle(FluencyTheme.gold)
            Text("\(xp) XP")
                .font(.system(.caption, design: .default, weight: .semibold))
                .foregroundStyle(FluencyTheme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(FluencyTheme.gold.opacity(0.2))
        .clipShape(Capsule())
    }
}

/// Streak badge — blue circle with flame + number
struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.caption)
                .foregroundStyle(.orange)
            Text("\(streak)")
                .font(.system(.caption, design: .default, weight: .bold))
                .foregroundStyle(FluencyTheme.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(FluencyTheme.primary.opacity(0.12))
        .clipShape(Capsule())
    }
}

/// Animated progress bar — blue fill, grey track, 8pt height
struct FluencyProgressBar: View {
    let progress: Double // 0.0 – 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(FluencyTheme.border)
                    .frame(height: 8)
                Capsule()
                    .fill(FluencyTheme.heroGradient)
                    .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 8)
                    .animation(FluencyTheme.springSnappy, value: progress)
            }
        }
        .frame(height: 8)
    }
}

/// Exercise word bubble — rounded pill, selectable
struct WordBubble: View {
    let word: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(word)
                .font(FluencyTheme.bodyMedium)
                .foregroundStyle(isSelected ? .white : FluencyTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? FluencyTheme.primary : FluencyTheme.border.opacity(0.5))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? FluencyTheme.primary : FluencyTheme.border, lineWidth: 1))
                .animation(FluencyTheme.springSnappy, value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

/// Slide-up feedback bar (correct/incorrect)
struct FeedbackBar: View {
    let isCorrect: Bool
    let correctAnswer: String
    let nativeNote: String?
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                Text(isCorrect ? "Correct!" : "Not quite")
                    .font(.system(.headline, design: .default, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }
            if !isCorrect {
                Text("Correct answer:")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(.white.opacity(0.8))
                Text(correctAnswer)
                    .font(FluencyTheme.bodyMedium)
                    .foregroundStyle(isCorrect ? .white : Color(hex: "#4ECCA3"))
            }
            if let note = nativeNote {
                Text(note)
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(.white.opacity(0.85))
                    .italic()
            }

            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(.body, design: .default, weight: .semibold))
                    .foregroundStyle(isCorrect ? FluencyTheme.success : FluencyTheme.error)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(isCorrect ? FluencyTheme.success : FluencyTheme.error)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}

/// Lesson card — large, gradient left border
struct LessonCard: View {
    let title: String
    let subtitle: String
    let xp: Int
    let estimatedMinutes: Int
    let isLocked: Bool
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Gradient left border
                FluencyTheme.heroGradient
                    .frame(width: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title)
                            .font(FluencyTheme.bodyMedium)
                            .foregroundStyle(isLocked ? FluencyTheme.textDisabled : FluencyTheme.textPrimary)
                        Spacer()
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(FluencyTheme.success)
                        } else if isLocked {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(FluencyTheme.textDisabled)
                        }
                    }
                    Text(subtitle)
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(FluencyTheme.textSecondary)
                    HStack(spacing: 10) {
                        XPBadge(xp: xp)
                        Label("\(estimatedMinutes) min", systemImage: "clock")
                            .font(FluencyTheme.captionFont)
                            .foregroundStyle(FluencyTheme.textSecondary)
                    }
                }
                .padding(FluencyTheme.cardPadding)
            }
            .background(FluencyTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}

// MARK: - Legacy font/color aliases (shims for older views)

extension FluencyTheme {
    static let headlineFont = Font.system(.headline, design: .default, weight: .semibold)
    static let titleFont = Font.system(.title2, design: .default, weight: .bold)
    static let accent = error // coral red (incorrect states)
    static let correctGreen = success.opacity(0.15)
    static let wrongRed = error.opacity(0.15)
    static let correctBorder = success
    static let wrongBorder = error
}

// MARK: - Secondary outline button style shim
struct FluencyOutlineButtonStyle: ButtonStyle {
    var color: Color = FluencyTheme.primary
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .default, weight: .semibold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .frame(height: FluencyTheme.buttonHeight)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color, lineWidth: 2))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

// MARK: - Legacy ButtonStyle shim (for existing code that uses FluencyButtonStyle)
struct FluencyButtonStyle: ButtonStyle {
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .default, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: FluencyTheme.buttonHeight)
            .background(isDisabled ? FluencyTheme.textDisabled : FluencyTheme.primary)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
