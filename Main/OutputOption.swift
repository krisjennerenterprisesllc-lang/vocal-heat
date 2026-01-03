import Foundation

enum OutputOption: CaseIterable, Codable {
    case device
    case bluetooth

    var title: String {
        switch self {
        case .device: return "Device"
        case .bluetooth: return "Bluetooth"
        }
    }
}
