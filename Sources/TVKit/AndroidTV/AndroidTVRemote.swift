import Foundation
import Security

// MARK: - Android TV Remote v2 (pairing :6467, control :6466)

@MainActor
public final class AndroidTVRemote: TVRemote {
    public let host: String
    private var conn: TLSConn?
    private var pairConn: TLSConn?
    private var active = false
    private var imeCounter = 0, fieldCounter = 0
    public var onPower: ((Bool) -> Void)?
    public var onVolume: ((_ level: Int, _ max: Int, _ muted: Bool) -> Void)?
    public var onDisconnect: (() -> Void)?

    public static let features = 622 // ping | key | ime | power | volume | app link

    public init(host: String) { self.host = host }

    // Pairing: TV shows a 6-char hex code after this returns.
    public func startPairing() async throws {
        pairConn?.cancel()
        let c = TLSConn(host: host, port: 6467, identity: try ClientIdentity.load())
        try await c.start()
        pairConn = c
        func step(_ field: Int, _ body: (inout PB) -> Void) async throws {
            try await c.send(PB.build { $0.int(1, 2); $0.int(2, 200); $0.msg(field, body) })
            let reply = try await c.read()
            guard reply.int(2) == 200 else { throw TVError.rejected("status \(reply.int(2) ?? 0)") }
        }
        try await step(10) { $0.string(1, "atvremote"); $0.string(2, "TCL Remote for Mac") }
        try await step(20) { $0.msg(1) { $0.int(1, 3); $0.int(2, 6) }; $0.int(3, 1) }
        try await step(30) { $0.msg(1) { $0.int(1, 3); $0.int(2, 6) }; $0.int(2, 1) }
    }

    public func finishPairing(code: String) async throws {
        guard let c = pairConn, let serverKey = c.serverKey,
              let server = rsaComponents(serverKey) else { throw TVError.closed }
        var cert: SecCertificate?
        SecIdentityCopyCertificate(try ClientIdentity.load(), &cert)
        guard let cert, let key = SecCertificateCopyKey(cert), let client = rsaComponents(key) else {
            throw TVError.identity("client key")
        }
        guard let secret = pairingSecret(client: client, server: server, code: code) else { throw TVError.badCode }
        try await c.send(PB.build { $0.int(1, 2); $0.int(2, 200); $0.msg(40) { $0.bytes(1, secret) } })
        let reply = try await c.read()
        c.cancel(); pairConn = nil
        guard reply.int(2) == 200 else { throw TVError.badCode }
    }

    public func cancelPairing() { pairConn?.cancel(); pairConn = nil }

    public func connect() async throws {
        if conn != nil, active { return }
        conn?.cancel()
        active = false
        let c = TLSConn(host: host, port: 6466, identity: try ClientIdentity.load())
        conn = c
        try await c.start()
        Task { [weak self] in
            while let msg = try? await c.read() { await self?.handle(msg, on: c) }
            if self?.conn === c { self?.conn = nil; self?.active = false; self?.onDisconnect?() }
        }
        // ponytail: polls for the handshake instead of a continuation; fine at 3s max.
        for _ in 0..<60 where !active { try await Task.sleep(for: .milliseconds(50)) }
        guard active else { c.cancel(); conn = nil; throw TVError.timeout }
    }

    private func handle(_ m: PBFields, on c: TLSConn) async {
        if m[1] != nil {
            try? await c.send(PB.build { $0.msg(1) {
                $0.int(1, Self.features)
                $0.msg(2) {
                    $0.string(1, "Mac"); $0.string(2, "Apple"); $0.int(3, 1)
                    $0.string(4, "1"); $0.string(5, "atvremote"); $0.string(6, "1.0.0")
                }
            } })
        }
        if m[2] != nil {
            try? await c.send(PB.build { $0.msg(2) { $0.int(1, Self.features) } })
            active = true
        }
        if let ping = m.msg(8) {
            try? await c.send(PB.build { $0.msg(9) { $0.int(1, ping.int(1) ?? 0) } })
        }
        if let ime = m.msg(21) {
            imeCounter = ime.int(1) ?? imeCounter
            fieldCounter = ime.int(2) ?? fieldCounter
        }
        if let start = m.msg(40) { onPower?((start.int(1) ?? 0) != 0) }
        if let v = m.msg(50), let max = v.int(6), max > 0 {
            onVolume?(v.int(7) ?? 0, max, (v.int(8) ?? 0) != 0)
        }
    }

    private func send(_ payload: Data) async throws {
        for attempt in 0..<2 {
            do {
                try await connect()
                try await conn!.send(payload)
                return
            } catch where attempt == 0 {
                conn?.cancel(); conn = nil; active = false
            }
        }
    }

    public func press(_ key: Key) async throws {
        try await send(PB.build { $0.msg(10) { $0.int(1, key.android); $0.int(2, 3) } })
    }

    /// Types by sending one key press per character, which works in any focused text field.
    /// ponytail: Remote v2 key events carry no Shift, so letters arrive lowercase; the IME
    /// batch-edit path keeps case but only works while the TV reports an open keyboard.
    public func type(_ text: String) async throws {
        for ch in text.lowercased() {
            guard let code = Self.keyCode(for: ch) else { continue }
            try await send(PB.build { $0.msg(10) { $0.int(1, code); $0.int(2, 3) } })
            try await Task.sleep(for: .milliseconds(30))
        }
    }

    /// Android KeyEvent code for a character, or nil if it can't be typed as a key.
    static func keyCode(for ch: Character) -> Int? {
        if let a = ch.asciiValue {
            if (97...122).contains(a) { return Int(a) - 97 + 29 }   // a-z -> KEYCODE_A...
            if (48...57).contains(a) { return Int(a) - 48 + 7 }     // 0-9 -> KEYCODE_0...
        }
        let symbols: [Character: Int] = [" ": 62, ".": 56, ",": 55, "-": 69, "=": 70, "@": 77, "/": 76, "'": 75,
                                         ";": 74, "[": 71, "]": 72, "\\": 73, "`": 68, "+": 81, "#": 18, "*": 17,
                                         "\n": 66]
        return symbols[ch]
    }

    public func apps() async -> [TVApp] {
        [("YouTube", "https://www.youtube.com"), ("Netflix", "https://www.netflix.com/title"),
         ("Prime Video", "https://app.primevideo.com"), ("Disney+", "https://www.disneyplus.com"),
         ("Spotify", "spotify://"), ("Max", "https://play.max.com"),
         ("Apple TV", "https://tv.apple.com")].map { TVApp(id: $0.1, name: $0.0) }
    }

    public func launch(_ app: TVApp) async throws {
        try await send(PB.build { $0.msg(90) { $0.string(1, app.id) } })
    }
}
