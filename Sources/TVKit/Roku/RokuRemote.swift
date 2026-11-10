import Foundation

// MARK: - Roku ECP (HTTP :8060, no pairing)

public final class RokuRemote: TVRemote {
    public let base: String
    public init(host: String) { base = "http://\(host):8060/" }

    private func post(_ path: String) async throws {
        guard let url = URL(string: base + path) else { return }
        var r = URLRequest(url: url, timeoutInterval: 4)
        r.httpMethod = "POST"
        let (_, resp) = try await URLSession.shared.data(for: r)
        if let code = (resp as? HTTPURLResponse)?.statusCode, code >= 300 { throw TVError.rejected("HTTP \(code)") }
    }

    public func connect() async throws {
        _ = try await URLSession.shared.data(from: URL(string: base + "query/device-info")!)
    }

    public func press(_ key: Key) async throws {
        guard !key.roku.isEmpty else { throw TVError.unsupported(key.label) }
        try await post("keypress/\(key.roku)")
    }

    public func type(_ text: String) async throws {
        for ch in text {
            let enc = String(ch).addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            try await post("keypress/Lit_\(enc)")
        }
    }

    public func apps() async -> [TVApp] {
        guard let (data, _) = try? await URLSession.shared.data(from: URL(string: base + "query/apps")!),
              let xml = String(data: data, encoding: .utf8) else { return [] }
        return Self.parseApps(xml, base: base)
    }

    public func launch(_ app: TVApp) async throws { try await post("launch/\(app.id)") }

    /// Friendly name from /query/device-info.
    public static func name(host: String) async -> String? {
        guard let (data, _) = try? await URLSession.shared.data(from: URL(string: "http://\(host):8060/query/device-info")!),
              let xml = String(data: data, encoding: .utf8) else { return nil }
        return parseName(xml)
    }

    // MARK: parsing (pure, unit-tested)

    static func parseApps(_ xml: String, base: String) -> [TVApp] {
        let re = try! Regex(#"<app id="([^"]+)"[^>]*>([^<]+)</app>"#)
        return xml.matches(of: re).compactMap { m in
            guard let id = m[1].substring, let name = m[2].substring else { return nil }
            return TVApp(id: String(id), name: String(name).replacingOccurrences(of: "&amp;", with: "&"),
                         icon: URL(string: base + "query/icon/\(id)"))
        }
    }

    /// Prefers the name the user gave the TV, then the friendly name, then the model.
    static func parseName(_ xml: String) -> String? {
        for tag in ["user-device-name", "friendly-device-name", "model-name"] {
            if let m = xml.firstMatch(of: try! Regex("<\(tag)>([^<]+)</\(tag)>")), let s = m[1].substring, !s.isEmpty {
                return String(s)
            }
        }
        return nil
    }
}
