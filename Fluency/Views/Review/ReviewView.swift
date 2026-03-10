import SwiftUI
import SwiftData

/// Review Tab — Spaced Repetition due-card review session
struct ReviewView: View {
    var user: User
    @Environment(\.modelContext) private var modelContext
    @Query private var allCards: [SRCard]
    @State private var session: SRSession?

    private var dueCards: [SRCard] {
        let now = Date()
        return allCards
            .filter { $0.userId == user.id && $0.nextReviewDate <= now }
            .sorted { $0.nextReviewDate < $1.nextReviewDate }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FluencyTheme.surface.ignoresSafeArea()

                if let session {
                    SRSessionView(session: session, onComplete: { self.session = nil })
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    reviewDashboard
                        .transition(.opacity)
                }
            }
            .animation(FluencyTheme.springSnappy, value: session == nil)
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Dashboard

    private var reviewDashboard: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Due card count banner
                dueBanner

                // Session starter
                if !dueCards.isEmpty {
                    FluencyPrimaryButton("Start Review (\(dueCards.count) cards)") {
                        session = SRSession(cards: dueCards, context: modelContext)
                    }
                    .padding(.horizontal, 20)
                }

                // Card stats grid
                cardStatsGrid

                // All cards list
                if !allCards.filter({ $0.userId == user.id }).isEmpty {
                    cardsList
                }

                Spacer().frame(height: 24)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Due Banner

    private var dueBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(dueCards.isEmpty ? FluencyTheme.success.opacity(0.15) : FluencyTheme.primary.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: dueCards.isEmpty ? "checkmark.circle.fill" : "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(dueCards.isEmpty ? FluencyTheme.success : FluencyTheme.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(dueCards.isEmpty ? "All caught up!" : "\(dueCards.count) cards due")
                    .font(.system(.title3, design: .default, weight: .bold))
                Text(dueCards.isEmpty
                    ? "Check back later for new reviews."
                    : "Review now to strengthen your memory.")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
            }

            Spacer()
        }
        .padding(FluencyTheme.cardPadding)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        .padding(.horizontal, 20)
    }

    // MARK: - Stats grid

    private var cardStatsGrid: some View {
        let userCards = allCards.filter { $0.userId == user.id }
        let mature = userCards.filter { $0.interval >= 21 }.count
        let learning = userCards.filter { $0.interval < 21 }.count

        return HStack(spacing: 12) {
            ReviewStatCard(value: "\(userCards.count)", label: "Total Cards", color: FluencyTheme.primary)
            ReviewStatCard(value: "\(dueCards.count)", label: "Due Today", color: dueCards.isEmpty ? FluencyTheme.success : FluencyTheme.gold)
            ReviewStatCard(value: "\(mature)", label: "Mature", color: FluencyTheme.success)
            ReviewStatCard(value: "\(learning)", label: "Learning", color: .orange)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Cards List

    private var cardsList: some View {
        let userCards = allCards.filter { $0.userId == user.id }.prefix(20)

        return VStack(alignment: .leading, spacing: 8) {
            Text("Your Vocabulary")
                .font(.system(.headline, design: .default, weight: .bold))
                .padding(.horizontal, 20)

            ForEach(Array(userCards), id: \.id) { card in
                SRCardRow(card: card)
                    .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - SR Session

@Observable
final class SRSession {
    var cards: [SRCard]
    var currentIndex = 0
    var showAnswer = false
    var sessionResults: [(cardId: UUID, quality: Int)] = []
    private let context: ModelContext

    init(cards: [SRCard], context: ModelContext) {
        self.cards = cards
        self.context = context
    }

    var currentCard: SRCard? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    var isComplete: Bool { currentIndex >= cards.count }
    var progress: Double { cards.isEmpty ? 1.0 : Double(currentIndex) / Double(cards.count) }

    func rate(_ quality: Int) {
        guard let card = currentCard else { return }
        sessionResults.append((cardId: card.id, quality: quality))
        SpacedRepetitionService.shared.updateCard(card, quality: quality)
        try? context.save()
        withAnimation(FluencyTheme.springSnappy) {
            currentIndex += 1
            showAnswer = false
        }
    }

    func revealAnswer() {
        withAnimation(FluencyTheme.springSnappy) { showAnswer = true }
    }
}

// MARK: - SR Session View

struct SRSessionView: View {
    @Bindable var session: SRSession
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            FluencyProgressBar(progress: session.progress)
                .padding(.horizontal, 20)
                .padding(.top, 16)

            HStack {
                Text("\(session.currentIndex) / \(session.cards.count)")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
                Spacer()
                Button("End Session") { onComplete() }
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            if session.isComplete {
                // Complete screen
                sessionCompleteView
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            } else if let card = session.currentCard {
                // Card view
                Spacer()
                ReviewCard(card: card, showAnswer: session.showAnswer)
                    .padding(.horizontal, 20)
                    .id(card.id) // force redraw on card change
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                Spacer()

                // Action buttons
                if session.showAnswer {
                    ratingButtons
                        .padding(.bottom, 32)
                } else {
                    FluencyPrimaryButton("Show Answer") { session.revealAnswer() }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }
        }
        .animation(FluencyTheme.springSnappy, value: session.isComplete)
        .animation(FluencyTheme.springSnappy, value: session.showAnswer)
    }

    // MARK: - Rating Buttons

    private var ratingButtons: some View {
        VStack(spacing: 10) {
            Text("How well did you remember?")
                .font(FluencyTheme.captionFont)
                .foregroundStyle(FluencyTheme.textSecondary)

            HStack(spacing: 10) {
                RatingButton(label: "Again", sublabel: "Forgot", color: FluencyTheme.error) { session.rate(1) }
                RatingButton(label: "Hard", sublabel: "Struggled", color: .orange) { session.rate(2) }
                RatingButton(label: "Good", sublabel: "Got it", color: FluencyTheme.primary) { session.rate(4) }
                RatingButton(label: "Easy", sublabel: "Obvious", color: FluencyTheme.success) { session.rate(5) }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Session Complete

    private var sessionCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🎉").font(.system(size: 80))
            Text("Session Complete!")
                .font(.system(.title, design: .default, weight: .bold))
            Text("You reviewed \(session.sessionResults.count) cards.")
                .font(FluencyTheme.bodyFont)
                .foregroundStyle(FluencyTheme.textSecondary)

            let avgQuality = session.sessionResults.isEmpty ? 0.0 :
                Double(session.sessionResults.map(\.quality).reduce(0, +)) / Double(session.sessionResults.count)
            Text(String(format: "Average score: %.1f/5", avgQuality))
                .font(FluencyTheme.bodyMedium)
                .foregroundStyle(FluencyTheme.primary)

            Spacer()
            FluencyPrimaryButton("Done", action: onComplete)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
        }
    }
}

// MARK: - Review Card (flip card)

struct ReviewCard: View {
    let card: SRCard
    let showAnswer: Bool
    @State private var flipDegrees: Double = 0

    var body: some View {
        ZStack {
            if !showAnswer {
                frontFace
            } else {
                backFace
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius + 4))
        .shadow(color: FluencyTheme.primary.opacity(0.1), radius: 16, y: 6)
        .rotation3DEffect(.degrees(flipDegrees), axis: (x: 0, y: 1, z: 0))
        .onChange(of: showAnswer) { _, newVal in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                flipDegrees = newVal ? 180 : 0
            }
        }
    }

    private var frontFace: some View {
        VStack(spacing: 16) {
            Text("🇪🇸")
                .font(.system(size: 40))
            Text(card.word)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(FluencyTheme.primary)
            Text(card.phonetic.isEmpty ? "" : "[\(card.phonetic)]")
                .font(FluencyTheme.captionFont)
                .foregroundStyle(FluencyTheme.textSecondary)
            Text("Tap 'Show Answer' when ready")
                .font(FluencyTheme.captionFont)
                .foregroundStyle(FluencyTheme.textDisabled)
                .padding(.top, 8)
        }
        .padding(24)
    }

    private var backFace: some View {
        VStack(spacing: 12) {
            Text(card.word)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(FluencyTheme.primary)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            Text(card.translation)
                .font(.system(.title2, design: .default, weight: .semibold))
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))

            if !card.exampleSentence.isEmpty {
                Divider()
                Text(card.exampleSentence)
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .padding(24)
    }
}

// MARK: - Rating Button

struct RatingButton: View {
    let label: String
    let sublabel: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(label)
                    .font(.system(.subheadline, design: .default, weight: .bold))
                    .foregroundStyle(color)
                Text(sublabel)
                    .font(.system(size: 10))
                    .foregroundStyle(FluencyTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SR Card Row

struct SRCardRow: View {
    let card: SRCard

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(card.word)
                    .font(FluencyTheme.bodyMedium)
                    .foregroundStyle(FluencyTheme.primary)
                Text(card.translation)
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("×\(card.repetition)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(FluencyTheme.textSecondary)
                if card.nextReviewDate <= Date() {
                    Text("Due")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(FluencyTheme.gold)
                        .clipShape(Capsule())
                } else {
                    Text("In \(daysUntil(card.nextReviewDate))d")
                        .font(.system(size: 11))
                        .foregroundStyle(FluencyTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, FluencyTheme.cardPadding)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func daysUntil(_ date: Date) -> Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0)
    }
}

// MARK: - Review Stat Card

struct ReviewStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(.title2, design: .default, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(FluencyTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(FluencyTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}
