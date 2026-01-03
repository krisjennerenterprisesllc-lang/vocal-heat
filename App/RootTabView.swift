import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var tabSelection: TabSelectionStore

    var body: some View {
        TabView(selection: $tabSelection.selected) {
            // Studio / Home
            AppHomeContainer()
                .tabItem {
                    Label("Studio", systemImage: "house.fill")
                }
                .tag(AppTab.studio)

            // Saved sessions
            NavigationStack {
                SessionsListView()
            }
            .tabItem {
                Label("Sessions", systemImage: "waveform.circle")
            }
            .tag(AppTab.sessions)

            // Hall of Fame
            NavigationStack {
                HallOfFameView()
            }
            .tabItem {
                Label("Hall of Fame", systemImage: "star.fill")
            }
            .tag(AppTab.hallOfFame)

            // Insights
            NavigationStack {
                InsightsView()
            }
            .tabItem {
                Label("Insights", systemImage: "chart.bar.xaxis")
            }
            .tag(AppTab.insights)
        }
    }
}
