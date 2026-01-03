import SwiftUI

struct AppHomeContainer: View {
    enum Route: Hashable {
        case record
        case duet
        case duetStudio
    }

    @EnvironmentObject private var tabSelection: TabSelectionStore

    @State private var path = NavigationPath()
    @State private var showSettings = false

    var body: some View {
        NavigationStack(path: $path) {
            AppHomeView(
                onRecord: { path.append(Route.record) },
                onDuetMode: { path.append(Route.duet) },
                onOpenSettings: { showSettings = true },
                onHome: {
                    // Ensure we’re on the Studio tab and pop to root.
                    tabSelection.selected = .studio
                    if !path.isEmpty {
                        path.removeLast(path.count)
                    }
                }
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .record:
                    RecordingView()
                case .duet:
                    // Enter via DuetStudioView (target selection), which itself navigates to DuetRecordingView.
                    DuetStudioView()
                case .duetStudio:
                    DuetStudioView()
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    AppHomeContainer()
        .environmentObject(SessionStore())
        .environmentObject(TabSelectionStore())
}
