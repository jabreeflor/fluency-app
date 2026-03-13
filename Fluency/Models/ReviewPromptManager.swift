import StoreKit
import SwiftUI

/// Manages SKStoreReviewController prompts per Apple guidelines.
///
/// Rules enforced:
/// - Only fires on the results screen (caller's responsibility — call `evaluate()` from LessonResultsView)
/// - Only if zero crashes in the current session
/// - 24h cooldown between any two prompts
/// - Each trigger fires at most once (tracked in UserDefaults)
/// - Apple caps at 3 prompts per 365 days; we respect that by not over-requesting
final class ReviewPromptManager {

    static let shared = ReviewPromptManager()
    private init() {}

    // MARK: - UserDefaults Keys

    private enum Key {
        static let lastPromptDate = "fluency.review.lastPromptDate"
        static let firedTriggers  = "fluency.review.firedTriggers"   // [String]
    }

    // MARK: - Triggers

    enum Trigger: String, CaseIterable {
        /// Fired after the user completes their 3rd lesson
        case afterLesson3    = "after_lesson_3"
        /// Fired after reaching a 7-day streak
        case afterStreak7    = "after_streak_7"
        /// Fired after completing a 100% accuracy lesson
        case firstPerfect    = "first_perfect"
    }

    // MARK: - Session crash tracker

    /// Increment this on any unhandled exception / crash reporter callback.
    /// ReviewPromptManager will not fire if this is > 0.
    private(set) var sessionCrashCount: Int = 0

    func recordCrash() {
        sessionCrashCount += 1
    }

    // MARK: - Main evaluation

    /// Evaluate whether a review prompt should fire. Call this from `LessonResultsView.onAppear`
    /// (or after the animation completes), not mid-lesson.
    ///
    /// - Parameters:
    ///   - totalLessonsCompleted: The user's cumulative completed lesson count
    ///   - currentStreak:         The user's current streak at the time of results
    ///   - accuracy:              Accuracy of the lesson just completed (0.0 – 1.0)
    ///   - scene:                 The `UIWindowScene` to present the review on (pass via @Environment)
    @MainActor
    func evaluate(
        totalLessonsCompleted: Int,
        currentStreak: Int,
        accuracy: Double,
        scene: UIWindowScene?
    ) {
        guard canPromptNow() else { return }

        // Determine the highest-priority trigger that applies and hasn't fired yet
        let trigger = pickTrigger(
            totalLessonsCompleted: totalLessonsCompleted,
            currentStreak: currentStreak,
            accuracy: accuracy
        )

        guard let trigger else { return }

        requestReview(trigger: trigger, scene: scene)
    }

    // MARK: - Private helpers

    @MainActor
    private func requestReview(trigger: Trigger, scene: UIWindowScene?) {
        guard let scene else { return }
        SKStoreReviewController.requestReview(in: scene)
        markFired(trigger)
        UserDefaults.standard.set(Date(), forKey: Key.lastPromptDate)
    }

    /// Returns `true` if we are allowed to show a prompt right now.
    private func canPromptNow() -> Bool {
        // No crashes this session
        guard sessionCrashCount == 0 else { return false }

        // 24h cooldown
        if let last = UserDefaults.standard.object(forKey: Key.lastPromptDate) as? Date {
            let elapsed = Date().timeIntervalSince(last)
            guard elapsed >= 86_400 else { return false } // 24h
        }

        return true
    }

    /// Pick the highest-priority applicable trigger that hasn't already fired.
    private func pickTrigger(
        totalLessonsCompleted: Int,
        currentStreak: Int,
        accuracy: Double
    ) -> Trigger? {
        // Priority order: afterLesson3 > afterStreak7 > firstPerfect
        let candidates: [(Trigger, Bool)] = [
            (.afterLesson3, totalLessonsCompleted >= 3),
            (.afterStreak7, currentStreak >= 7),
            (.firstPerfect, accuracy >= 1.0),
        ]

        for (trigger, applies) in candidates {
            if applies && !hasFired(trigger) {
                return trigger
            }
        }
        return nil
    }

    private func hasFired(_ trigger: Trigger) -> Bool {
        let fired = UserDefaults.standard.stringArray(forKey: Key.firedTriggers) ?? []
        return fired.contains(trigger.rawValue)
    }

    private func markFired(_ trigger: Trigger) {
        var fired = UserDefaults.standard.stringArray(forKey: Key.firedTriggers) ?? []
        if !fired.contains(trigger.rawValue) {
            fired.append(trigger.rawValue)
            UserDefaults.standard.set(fired, forKey: Key.firedTriggers)
        }
    }
}
