import SwiftUI

struct AppRouter: View {
    @StateObject private var sessionStore = SessionStore()

    var body: some View {
        NavigationStack {
            AppHomeView()
        }
        .environmentObject(sessionStore)
    }
}

#Preview {
    NavigationStack {
        AppHomeView()
    }
    .environmentObject(SessionStore())
}
