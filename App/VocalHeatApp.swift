import SwiftUI

@main
struct VocalHeatApp: App {
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var tabSelection = TabSelectionStore()
    @StateObject private var duetSession = DuetSessionStore() // ADD THIS
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if hasSeenOnboarding {
                    RootTabView()
                } else {
                    OnboardingView(onFinished: {
                        hasSeenOnboarding = true
                    })
                }
            }
            .environmentObject(sessionStore)
            .environmentObject(tabSelection)
            .environmentObject(duetSession) // AND ADD THIS
        }
    }
}
