import Foundation
import SwiftData

/// SM-2 Spaced Repetition implementation
/// Reference: https://www.supermemo.com/en/archives1990-2015/english/ol/sm2
final class SpacedRepetitionService {
    static let shared = SpacedRepetitionService()
    private init() {}

    // MARK: - Update Card (SM-2 algorithm)

    /// quality: 0-5
    ///   5 = perfect response
    ///   4 = correct, slight hesitation
    ///   3 = correct with difficulty
    ///   2 = incorrect but correct answer felt easy to recall
    ///   1 = incorrect, correct answer was hard
    ///   0 = complete blackout
    func update(card: SRCard, quality: Int) {
        card.totalReviews += 1
        card.lastReviewDate = Date()

        if quality >= 3 {
            // Correct
            card.correctReviews += 1

            switch card.repetition {
            case 0: card.interval = 1
            case 1: card.interval = 6
            default: card.interval = Int(Double(card.interval) * card.easeFactor)
            }

            card.repetition += 1
        } else {
            // Incorrect — reset
            card.repetition = 0
            card.interval = 1
        }

        // Update ease factor
        let q = Double(quality)
        let newEF = card.easeFactor + (0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02))
        card.easeFactor = max(1.3, newEF)

        // Schedule next review
        card.nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: card.interval,
            to: Date()
        ) ?? Date()
    }

    // MARK: - Fetch Due Cards

    func dueCards(for user: User) -> [SRCard] {
        user.srCards.filter { $0.isDue }.sorted { $0.nextReviewDate < $1.nextReviewDate }
    }

    // MARK: - Create or update card for a word

    func upsertCard(
        for word: WordEntry,
        lessonId: String,
        user: User,
        context: ModelContext
    ) -> SRCard {
        // Check if card exists
        if let existing = user.srCards.first(where: {
            $0.word == word.word && $0.languageCode == user.selectedLanguageCode
        }) {
            return existing
        }

        // Create new card
        let card = SRCard(
            userId: user.id,
            word: word.word,
            translation: word.translation,
            languageCode: user.selectedLanguageCode,
            lessonId: lessonId
        )
        context.insert(card)
        user.srCards.append(card)
        return card
    }

    // MARK: - Quality mapping

    func quality(isCorrect: Bool, timeSpent: TimeInterval, expectedTime: TimeInterval = 5.0) -> Int {
        if !isCorrect { return 1 }
        // Correct answers — grade on speed
        if timeSpent <= expectedTime { return 5 }
        if timeSpent <= expectedTime * 2 { return 4 }
        return 3
    }
}
