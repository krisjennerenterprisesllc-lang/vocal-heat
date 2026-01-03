import SwiftUI
import Combine

enum AppTab: Hashable {
    case studio
    case sessions
    case hallOfFame
    case insights
}

final class TabSelectionStore: ObservableObject {
    @Published var selected: AppTab = .studio
}
