import Foundation

public enum AnalysisStatus: Codable, Sendable, Equatable {
    case notAnalyzed
    case analyzed(SessionMetrics)
    case tooShort(minimumSeconds: Int)
    case error(code: String, message: String)

    private enum CodingKeys: String, CodingKey { case kind, payload }

    private enum Kind: String, Codable {
        case notAnalyzed, analyzed, tooShort, error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .notAnalyzed:
            self = .notAnalyzed
        case .analyzed:
            let metrics = try container.decode(SessionMetrics.self, forKey: .payload)
            self = .analyzed(metrics)
        case .tooShort:
            let min = try container.decode(Int.self, forKey: .payload)
            self = .tooShort(minimumSeconds: min)
        case .error:
            let pair = try container.decode([String: String].self, forKey: .payload)
            self = .error(code: pair["code"] ?? "unknown", message: pair["message"] ?? "Unknown error")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .notAnalyzed:
            try container.encode(Kind.notAnalyzed, forKey: .kind)
        case .analyzed(let metrics):
            try container.encode(Kind.analyzed, forKey: .kind)
            try container.encode(metrics, forKey: .payload)
        case .tooShort(let min):
            try container.encode(Kind.tooShort, forKey: .kind)
            try container.encode(min, forKey: .payload)
        case .error(let code, let message):
            try container.encode(Kind.error, forKey: .kind)
            try container.encode(["code": code, "message": message], forKey: .payload)
        }
    }
}
