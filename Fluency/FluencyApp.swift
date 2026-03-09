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
        if let user = users.first {
            MainTabView(user: user)
        } else {
            OnboardingView()
        }
    }
}
