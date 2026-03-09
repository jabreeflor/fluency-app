import Foundation
import SwiftData
import Combine

/// Manages heart refill timer — 1 heart every 30 minutes when below max
@MainActor
final class HeartRefillService: ObservableObject {
    static let shared = HeartRefillService()
    private var timer: Timer?
    private let maxHearts = 5
    private let refillIntervalSeconds: TimeInterval = 1800 // 30 min

    private init() {}

    func start(user: User, context: ModelContext) {
        stop()
        tick(user: user, context: context)
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick(user: user, context: context)
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick(user: User, context: ModelContext) {
        guard user.hearts < maxHearts else { return }

        let elapsed = Date().timeIntervalSince(user.lastHeartRefillDate)
        let heartsToAdd = Int(elapsed / refillIntervalSeconds)

        if heartsToAdd > 0 {
            let added = min(heartsToAdd, maxHearts - user.hearts)
            user.hearts = min(user.hearts + added, maxHearts)
            // Advance refill timestamp by the intervals consumed
            user.lastHeartRefillDate = user.lastHeartRefillDate.addingTimeInterval(
                Double(added) * refillIntervalSeconds
            )
            try? context.save()
        }
    }

    /// How many seconds until next heart refill
    func secondsUntilNextHeart(user: User) -> TimeInterval? {
        guard user.hearts < maxHearts else { return nil }
        let elapsed = Date().timeIntervalSince(user.lastHeartRefillDate)
        let remaining = refillIntervalSeconds - elapsed.truncatingRemainder(dividingBy: refillIntervalSeconds)
        return remaining
    }

    func formattedTimeUntilHeart(user: User) -> String? {
        guard let seconds = secondsUntilNextHeart(user: user) else { return nil }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
