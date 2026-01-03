import SwiftUI
import Combine

struct ReferenceTrack: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let artist: String
    let duration: String
    let key: String
    let tempo: Int
}

@MainActor
final class DuetSessionStore: ObservableObject {
    @Published var selectedTrack: ReferenceTrack?
    @Published var enableCountIn: Bool = true
    @Published var outputDevice: OutputOption = .device
}
