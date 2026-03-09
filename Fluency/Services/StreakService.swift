import Foundation
import UserNotifications
import SwiftData

/// Manages daily streaks and reminder notifications
@MainActor
final class StreakService: ObservableObject {
    static let shared = StreakService()
    private init() {}

    // MARK: - Streak Update

    func updateStreak(for user: User) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastActive = calendar.startOfDay(for: user.lastActiveDate)
        let daysDiff = calendar.dateComponents([.day], from: lastActive, to: today).day ?? 0

        switch daysDiff {
        case 0:
            break // already active today, no change
        case 1:
            user.currentStreak += 1
            user.longestStreak = max(user.longestStreak, user.currentStreak)
        default:
            user.currentStreak = 1 // broken streak, reset to 1 for today
        }

        user.lastActiveDate = Date()
    }

    func isStreakAtRisk(for user: User) -> Bool {
        let calendar = Calendar.current
        let lastActive = calendar.startOfDay(for: user.lastActiveDate)
        let today = calendar.startOfDay(for: Date())
        let daysDiff = calendar.dateComponents([.day], from: lastActive, to: today).day ?? 0
        return daysDiff == 1 // haven't studied today but did yesterday
    }

    // MARK: - Notifications

    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleDailyReminder(at hour: Int = 19, minute: Int = 0) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["fluency.daily.reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Time to practice Spanish! 🇪🇸"
        content.body = "Keep your streak alive — your daily lesson is waiting."
        content.sound = .default
        content.badge = 1

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "fluency.daily.reminder",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    func scheduleStreakRiskReminder(for user: User) async {
        guard isStreakAtRisk(for: user) else { return }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["fluency.streak.risk"])

        let content = UNMutableNotificationContent()
        content.title = "Your \(user.currentStreak)-day streak is at risk! 🔥"
        content.body = "Complete one lesson before midnight to keep it going."
        content.sound = .default

        // Fire at 9 PM
        var components = DateComponents()
        components.hour = 21
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "fluency.streak.risk",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)
    }
}
