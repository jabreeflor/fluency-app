import SwiftUI
import SwiftData

@main
struct FluencyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            UserProgress.self,
            LessonResult.self,
            SRCard.self,
            UserAchievement.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRoot()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct AppRoot: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    var body: some View {
        Group {
            if let user = users.first {
                MainTabView(user: user)
                    .onAppear {
                        // Start heart refill timer
                        HeartRefillService.shared.start(user: user, context: modelContext)
                        // Clear notification badge
                        StreakService.shared.clearBadge()
                        // Schedule daily reminder if not set
                        Task {
                            let granted = await StreakService.shared.requestNotificationPermission()
                            if granted {
                                await StreakService.shared.scheduleDailyReminder(at: 19, minute: 0)
                                await StreakService.shared.scheduleStreakRiskReminder(for: user)
                            }
                        }
                    }
            } else {
                OnboardingView()
            }
        }
    }
}
