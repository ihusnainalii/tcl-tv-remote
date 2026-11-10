import Foundation

struct TV: Codable, Hashable, Identifiable {
    enum Kind: String, Codable, CaseIterable { case androidTV = "Google TV", roku = "Roku TV" }
    var name: String
    var host: String
    var kind: Kind
    var id: String { "\(kind.rawValue)-\(host)" }
}

struct TVApp: Hashable, Identifiable {
    var id: String   // Roku app id, or Android TV app link
    var name: String
}

enum TVError: LocalizedError {
    case closed, timeout, rejected(String), badCode, identity(String)
    var errorDescription: String? {
        switch self {
        case .closed: "Connection closed"
        case .timeout: "TV did not respond"
        case .rejected(let s): "TV rejected request (\(s))"
        case .badCode: "Wrong pairing code"
        case .identity(let s): "Certificate error: \(s)"
        }
    }
}

enum Key: String, CaseIterable {
    case power, home, back, menu, info, search
    case up, down, left, right, ok
    case volUp, volDown, mute, chUp, chDown
    case playPause, rewind, forward
    case tuner, hdmi1, hdmi2, hdmi3, hdmi4
    case n0, n1, n2, n3, n4, n5, n6, n7, n8, n9

    var digit: Int? { rawValue.first == "n" ? Int(rawValue.dropFirst()) : nil }

    /// Roku ECP key names.
    var roku: String {
        if let d = digit { return "Lit_\(d)" }
        return switch self {
        case .power: "Power"; case .home: "Home"; case .back: "Back"; case .menu, .info: "Info"
        case .search: "Search"; case .up: "Up"; case .down: "Down"; case .left: "Left"; case .right: "Right"
        case .ok: "Select"; case .volUp: "VolumeUp"; case .volDown: "VolumeDown"; case .mute: "VolumeMute"
        case .chUp: "ChannelUp"; case .chDown: "ChannelDown"; case .playPause: "Play"
        case .rewind: "Rev"; case .forward: "Fwd"; case .tuner: "InputTuner"
        case .hdmi1: "InputHDMI1"; case .hdmi2: "InputHDMI2"; case .hdmi3: "InputHDMI3"; case .hdmi4: "InputHDMI4"
        default: ""
        }
    }

    /// Android KeyEvent codes.
    var android: Int {
        if let d = digit { return 7 + d }
        return switch self {
        case .power: 26; case .home: 3; case .back: 4; case .menu: 82; case .info: 165; case .search: 84
        case .up: 19; case .down: 20; case .left: 21; case .right: 22; case .ok: 23
        case .volUp: 24; case .volDown: 25; case .mute: 164; case .chUp: 166; case .chDown: 167
        case .playPause: 85; case .rewind: 89; case .forward: 90; case .tuner: 170
        case .hdmi1: 243; case .hdmi2: 244; case .hdmi3: 245; case .hdmi4: 246
        default: 0
        }
    }
}

protocol TVRemote: AnyObject {
    func connect() async throws
    func press(_ key: Key) async throws
    func type(_ text: String) async throws
    func apps() async -> [TVApp]
    func launch(_ app: TVApp) async throws
}

// MARK: - Roku ECP (HTTP :8060, no pairing)

final class RokuRemote: TVRemote {
    let base: String
    init(host: String) { base = "http://\(host):8060/" }

    private func post(_ path: String) async throws {
        guard let url = URL(string: base + path) else { return }
        var r = URLRequest(url: url, timeoutInterval: 4)
        r.httpMethod = "POST"
        let (_, resp) = try await URLSession.shared.data(for: r)
        if let code = (resp as? HTTPURLResponse)?.statusCode, code >= 300 { throw TVError.rejected("HTTP \(code)") }
    }

    func connect() async throws {
        _ = try await URLSession.shared.data(from: URL(string: base + "query/device-info")!)
    }

    func press(_ key: Key) async throws { try await post("keypress/\(key.roku)") }

    func type(_ text: String) async throws {
        for ch in text {
            let enc = String(ch).addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            try await post("keypress/Lit_\(enc)")
        }
    }

    func apps() async -> [TVApp] {
        guard let (data, _) = try? await URLSession.shared.data(from: URL(string: base + "query/apps")!),
              let xml = String(data: data, encoding: .utf8) else { return [] }
        let re = try! Regex(#"<app id="([^"]+)"[^>]*>([^<]+)</app>"#)
        return xml.matches(of: re).compactMap { m in
            guard let id = m[1].substring, let name = m[2].substring else { return nil }
            return TVApp(id: String(id), name: String(name).replacingOccurrences(of: "&amp;", with: "&"))
        }
    }

    func launch(_ app: TVApp) async throws { try await post("launch/\(app.id)") }

    /// Friendly name from /query/device-info.
    static func name(host: String) async -> String? {
        guard let (data, _) = try? await URLSession.shared.data(from: URL(string: "http://\(host):8060/query/device-info")!),
              let xml = String(data: data, encoding: .utf8) else { return nil }
        for tag in ["user-device-name", "friendly-device-name", "model-name"] {
            if let m = xml.firstMatch(of: try! Regex("<\(tag)>([^<]+)</\(tag)>")), let s = m[1].substring, !s.isEmpty {
                return String(s)
            }
        }
        return nil
    }
}
