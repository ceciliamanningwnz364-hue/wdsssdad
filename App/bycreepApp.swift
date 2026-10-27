import SwiftUI
import SwiftData

@main
struct bycreepApp: App {
    init() {
        let a = UITabBarAppearance()
        a.configureWithOpaqueBackground()
        a.backgroundColor = .black
        UITabBar.appearance().standardAppearance = a
        UITabBar.appearance().scrollEdgeAppearance = a
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(Theme.red)
        }
        .modelContainer(for: [Workout.self, Exercise.self, WorkoutLog.self,
                              ProgressPhoto.self, BodyEntry.self, FoodEntry.self])
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var ctx

    var body: some View {
        TabView {
            WorkoutsView().tabItem { Label("Тренировки", systemImage: "dumbbell.fill") }
            NutritionView().tabItem { Label("Питание", systemImage: "fork.knife") }
            ProgressTab().tabItem { Label("Прогресс", systemImage: "camera.viewfinder") }
            ProfileView().tabItem { Label("Профиль", systemImage: "person.fill") }
        }
        .task { Sync.widget(ctx) }
    }
}
