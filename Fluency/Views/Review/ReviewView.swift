import SwiftUI

struct ReviewView: View {
    let user: User
    @State private var dueCards: [SRCard] = []

    var body: some View {
        NavigationStack {
            Group {
                if dueCards.isEmpty {
                    VStack(spacing: 20) {
                        Text("🎉")
                            .font(.system(size: 72))
                        Text("All caught up!")
                            .font(FluencyTheme.titleFont)
                        Text("No reviews due right now.\nCome back later!")
                            .font(FluencyTheme.bodyFont)
                            .foregroundStyle(FluencyTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            ForEach(dueCards) { card in
                                SRCardRow(card: card)
                            }
                        } header: {
                            Text("\(dueCards.count) card\(dueCards.count != 1 ? "s" : "") due")
                                .font(FluencyTheme.captionFont)
                        }
                    }
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            dueCards = SpacedRepetitionService.shared.dueCards(for: user)
        }
    }
}

struct SRCardRow: View {
    let card: SRCard

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.word)
                    .font(FluencyTheme.headlineFont)
                Text(card.translation)
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Interval: \(card.interval)d")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)
                Text("\(Int(card.successRate * 100))% accuracy")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(card.successRate >= 0.7 ? FluencyTheme.primary : FluencyTheme.accent)
            }
        }
        .padding(.vertical, 4)
    }
}
