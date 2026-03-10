import SwiftUI

/// Screen 3.1 — Lesson intro per Ellis spec
/// Topic badge, word count, preview dots, difficulty, Begin CTA
struct LessonIntroView: View {
    let lesson: LessonContent
    let user: User
    @Environment(\.dismiss) private var dismiss
    @State private var showSession = false
    @State private var appeared = false

    private var previewWords: [WordEntry] {
        Array(lesson.newWords.prefix(4))
    }

    var body: some View {
        ZStack {
            FluencyTheme.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(FluencyTheme.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView {
                    VStack(spacing: 28) {

                        // Hero flag + lesson name
                        heroHeader
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                            .animation(.spring(response: 0.5).delay(0.05), value: appeared)

                        // Stats row
                        statsRow
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(.spring(response: 0.5).delay(0.15), value: appeared)

                        // Word preview
                        wordPreview
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(.spring(response: 0.5).delay(0.25), value: appeared)

                        Spacer().frame(height: 16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }

                // CTA
                FluencyPrimaryButton("Begin Lesson") { showSession = true }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.4).delay(0.35), value: appeared)
            }
        }
        .onAppear { appeared = true }
        .fullScreenCover(isPresented: $showSession) {
            LessonSessionView(lesson: lesson, user: user)
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: 14) {
            // Flag + gradient ring
            ZStack {
                Circle()
                    .fill(FluencyTheme.heroGradient)
                    .frame(width: 90, height: 90)
                    .opacity(0.15)
                Text("🇪🇸")
                    .font(.system(size: 52))
            }

            VStack(spacing: 6) {
                // Unit badge
                Text(lesson.unit.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FluencyTheme.primary)
                    .kerning(1.2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(FluencyTheme.primary.opacity(0.1))
                    .clipShape(Capsule())

                Text(lesson.name)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(lesson.description)
                    .font(FluencyTheme.bodyFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            IntroStat(icon: "textformat.abc", label: "\(lesson.newWords.count) words", color: FluencyTheme.primary)
            Divider().frame(height: 40)
            IntroStat(icon: "clock", label: "~\(lesson.estimatedMinutes) min", color: .blue)
            Divider().frame(height: 40)
            IntroStat(icon: "star.fill", label: "+\(lesson.xpReward) XP", color: FluencyTheme.gold)
        }
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    // MARK: - Word Preview

    private var wordPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("You'll learn")
                    .font(.system(.headline, design: .default, weight: .bold))
                Spacer()
                Text("\(lesson.newWords.count) words total")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
            }

            ForEach(previewWords) { word in
                HStack {
                    Text(word.word)
                        .font(FluencyTheme.bodyMedium)
                        .foregroundStyle(FluencyTheme.primary)
                    if let phonetic = word.phonetic {
                        Text("[\(phonetic)]")
                            .font(FluencyTheme.captionFont)
                            .foregroundStyle(FluencyTheme.textSecondary)
                    }
                    Spacer()
                    Text(word.translation)
                        .font(FluencyTheme.bodyFont)
                        .foregroundStyle(FluencyTheme.textSecondary)
                }
                .padding(.horizontal, FluencyTheme.cardPadding)
                .padding(.vertical, 10)
                .background(FluencyTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if lesson.newWords.count > 4 {
                Text("+ \(lesson.newWords.count - 4) more words")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

private struct IntroStat: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundStyle(color)
            Text(label).font(.system(.subheadline, design: .default, weight: .medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}
