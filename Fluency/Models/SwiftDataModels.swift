import Foundation
import SwiftData
import SwiftUI

// MARK: - User

@Model final class User {
    var id: UUID = UUID()
    var username: String = ""
    var totalXP: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var hearts: Int = 5
    var lastHeartRefillDate: Date = Date()
    var selectedLanguageCode: String = "es"
    var dailyXPGoal: Int = 20
    var lastActiveDate: Date = Date()
    var subscriptionRaw: String = SubscriptionType.free.rawValue

    @Relationship(deleteRule: .cascade) var progress: [UserProgress] = []
    @Relationship(deleteRule: .cascade) var lessonResults: [LessonResult] = []
    @Relationship(deleteRule: .cascade) var srCards: [SRCard] = []
    @Relationship(deleteRule: .cascade) var achievements: [UserAchievement] = []

    init(username: String = "Learner") {
        self.id = UUID()
        self.username = username
        self.totalXP = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.hearts = 5
        self.lastHeartRefillDate = Date()
        self.selectedLanguageCode = "es"
        self.dailyXPGoal = 20
        self.lastActiveDate = Date()
        self.subscriptionRaw = SubscriptionType.free.rawValue
    }

    var subscription: SubscriptionType {
        get { SubscriptionType(rawValue: subscriptionRaw) ?? .free }
        set { subscriptionRaw = newValue.rawValue }
    }

    var isPremium: Bool { subscription == .premium }

    var todayXP: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return lessonResults
            .filter { ($0.completedAt ?? Date.distantPast) >= today }
            .reduce(0) { $0 + $1.xpEarned }
    }

    var dailyGoalProgress: Double {
        min(Double(todayXP) / Double(dailyXPGoal), 1.0)
    }

    var needsHeartRefill: Bool {
        hearts < 5 && Date().timeIntervalSince(lastHeartRefillDate) >= 1800
    }
}

enum SubscriptionType: String, Codable {
    case free, premium
}

// MARK: - User Progress (per lesson)

@Model final class UserProgress {
    var id: UUID = UUID()
    var userId: UUID = UUID()
    var languageCode: String = ""
    var unitId: String = ""
    var lessonId: String = ""
    var isCompleted: Bool = false
    var completedAt: Date?
    var bestScore: Double = 0
    var attempts: Int = 0
    var xpEarned: Int = 0
    var totalTimeSpent: TimeInterval = 0

    @Relationship(inverse: \User.progress) var user: User?

    init(userId: UUID, languageCode: String, unitId: String, lessonId: String) {
        self.id = UUID()
        self.userId = userId
        self.languageCode = languageCode
        self.unitId = unitId
        self.lessonId = lessonId
    }
}

// MARK: - Lesson Result (per attempt)

@Model final class LessonResult {
    var id: UUID = UUID()
    var userId: UUID = UUID()
    var lessonId: String = ""
    var languageCode: String = ""
    var startedAt: Date = Date()
    var completedAt: Date?
    var score: Double = 0
    var correctAnswers: Int = 0
    var totalQuestions: Int = 0
    var xpEarned: Int = 0
    var heartsLost: Int = 0
    var timeSpent: TimeInterval = 0

    @Relationship(inverse: \User.lessonResults) var user: User?

    init(userId: UUID, lessonId: String, languageCode: String) {
        self.id = UUID()
        self.userId = userId
        self.lessonId = lessonId
        self.languageCode = languageCode
        self.startedAt = Date()
    }

    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions)
    }
}

// MARK: - Spaced Repetition Card (SM-2)

@Model final class SRCard {
    var id: UUID = UUID()
    var userId: UUID = UUID()
    var word: String = ""
    var translation: String = ""
    var languageCode: String = ""
    var lessonId: String = ""

    // SM-2 state
    var easeFactor: Double = 2.5
    var interval: Int = 1          // days
    var repetition: Int = 0        // successful review count
    var nextReviewDate: Date = Date()
    var lastReviewDate: Date?

    // Stats
    var totalReviews: Int = 0
    var correctReviews: Int = 0

    @Relationship(inverse: \User.srCards) var user: User?

    init(userId: UUID, word: String, translation: String, languageCode: String, lessonId: String) {
        self.id = UUID()
        self.userId = userId
        self.word = word
        self.translation = translation
        self.languageCode = languageCode
        self.lessonId = lessonId
        self.nextReviewDate = Date()
    }

    var isDue: Bool { Date() >= nextReviewDate }

    var successRate: Double {
        guard totalReviews > 0 else { return 0 }
        return Double(correctReviews) / Double(totalReviews)
    }
}

// MARK: - Achievements

@Model final class UserAchievement {
    var id: UUID = UUID()
    var userId: UUID = UUID()
    var typeRaw: String = ""
    var isUnlocked: Bool = false
    var unlockedAt: Date?
    var progress: Int = 0
    var target: Int = 1

    @Relationship(inverse: \User.achievements) var user: User?

    init(userId: UUID, type: AchievementType) {
        self.id = UUID()
        self.userId = userId
        self.typeRaw = type.rawValue
        self.target = type.defaultTarget
    }

    var type: AchievementType {
        AchievementType(rawValue: typeRaw) ?? .firstLesson
    }
}

enum AchievementType: String, CaseIterable {
    case firstLesson, streak3, streak7, streak30
    case lessons10, lessons50, perfectScore

    var title: String {
        switch self {
        case .firstLesson: return "First Steps"
        case .streak3: return "3-Day Streak"
        case .streak7: return "Week Warrior"
        case .streak30: return "Month Master"
        case .lessons10: return "Learning Machine"
        case .lessons50: return "Scholar"
        case .perfectScore: return "Perfectionist"
        }
    }

    var icon: String {
        switch self {
        case .firstLesson: return "star.fill"
        case .streak3, .streak7, .streak30: return "flame.fill"
        case .lessons10, .lessons50: return "book.fill"
        case .perfectScore: return "target"
        }
    }

    var defaultTarget: Int {
        switch self {
        case .firstLesson: return 1
        case .streak3: return 3
        case .streak7: return 7
        case .streak30: return 30
        case .lessons10: return 10
        case .lessons50: return 50
        case .perfectScore: return 1
        }
    }
}
