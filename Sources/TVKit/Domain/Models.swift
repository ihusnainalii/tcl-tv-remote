import Foundation

public struct TV: Codable, Hashable, Identifiable {
    public enum Kind: String, Codable, CaseIterable { case androidTV = "Google TV", roku = "Roku TV" }
    public var name: String
    public var host: String
    public var kind: Kind
    public var id: String { "\(kind.rawValue)-\(host)" }

    public init(name: String, host: String, kind: Kind) { self.name = name; self.host = host; self.kind = kind }
}

public struct TVApp: Hashable, Identifiable, Codable {
    public var id: String   // Roku app id, or Android TV app link
    public var name: String
    /// Icon served by the TV itself (Roku). Nil means look it up (see AppIconResolver).
    public var icon: URL?

    public init(id: String, name: String, icon: URL? = nil) { self.id = id; self.name = name; self.icon = icon }
}

public enum TVError: LocalizedError {
    case closed, timeout, rejected(String), badCode, identity(String), unsupported(String)
    public var errorDescription: String? {
        switch self {
        case .unsupported(let k): "\(k) isn't available on this TV"
        case .closed: "Connection closed"
        case .timeout: "TV did not respond"
        case .rejected(let s): "TV rejected request (\(s))"
        case .badCode: "Wrong pairing code"
        case .identity(let s): "Certificate error: \(s)"
        }
    }
}

/// A TV we've connected to before.
public struct KnownTV: Codable, Hashable, Identifiable {
    public var tv: TV
    public var lastUsed: Date
    // Optional so data saved by older versions still decodes.
    public var favorite: Bool?
    public var nickname: String?
    public var favoriteApps: [String]?
    public var recentApps: [String]?
    public var customApps: [TVApp]?
    public var id: String { tv.id }

    public init(tv: TV, lastUsed: Date) { self.tv = tv; self.lastUsed = lastUsed }

    public var name: String { nickname?.isEmpty == false ? nickname! : tv.name }
}
