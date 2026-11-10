import CryptoKit
import Foundation
import Network
import Security

// MARK: - Client certificate (generated once, kept in Application Support)

enum ClientIdentity {
    static let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("TCLRemote", isDirectory: true)
    private static let pass = "tclremote"
    private static var cached: SecIdentity?

    static func load() throws -> SecIdentity {
        if let cached { return cached }
        let p12 = dir.appendingPathComponent("client.p12")
        if !FileManager.default.fileExists(atPath: p12.path) { try generate(p12) }
        let data = try Data(contentsOf: p12)
        let opts: [String: Any] = [kSecImportExportPassphrase as String: pass, kSecImportToMemoryOnly as String: true]
        var items: CFArray?
        let status = SecPKCS12Import(data as CFData, opts as CFDictionary, &items)
        guard status == errSecSuccess, let first = (items as? [[String: Any]])?.first,
              let id = first[kSecImportItemIdentity as String] else { throw TVError.identity("import \(status)") }
        cached = (id as! SecIdentity)
        return cached!
    }

    // ponytail: shells out to the system LibreSSL instead of hand-writing X.509 DER.
    private static func generate(_ p12: URL) throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let key = dir.appendingPathComponent("key.pem").path, cert = dir.appendingPathComponent("cert.pem").path
        try openssl(["req", "-x509", "-newkey", "rsa:2048", "-keyout", key, "-out", cert, "-days", "3650", "-nodes", "-subj", "/CN=atvremote"])
        try openssl(["pkcs12", "-export", "-inkey", key, "-in", cert, "-out", p12.path, "-passout", "pass:\(pass)",
                     "-certpbe", "PBE-SHA1-3DES", "-keypbe", "PBE-SHA1-3DES"])
        try? FileManager.default.removeItem(atPath: key)
    }

    private static func openssl(_ args: [String]) throws {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/openssl")
        p.arguments = args
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try p.run(); p.waitUntilExit()
        guard p.terminationStatus == 0 else { throw TVError.identity("openssl \(args[0]) failed") }
    }
}

/// RSA public key -> (modulus, exponent) with DER leading zeros stripped.
func rsaComponents(_ key: SecKey) -> (Data, Data)? {
    guard let der = SecKeyCopyExternalRepresentation(key, nil) as Data? else { return nil }
    return rsaComponents(pkcs1: der)
}

/// Parses PKCS#1 RSAPublicKey: SEQUENCE { INTEGER n, INTEGER e }.
func rsaComponents(pkcs1 der: Data) -> (Data, Data)? {
    let b = [UInt8](der)
    var i = 0
    func len() -> Int? {
        guard i < b.count else { return nil }
        let first = Int(b[i]); i += 1
        if first < 0x80 { return first }
        var n = 0
        for _ in 0..<(first & 0x7F) { guard i < b.count else { return nil }; n = n << 8 | Int(b[i]); i += 1 }
        return n
    }
    func integer() -> Data? {
        guard i < b.count, b[i] == 0x02 else { return nil }
        i += 1
        guard let n = len(), i + n <= b.count else { return nil }
        var v = Array(b[i..<i + n]); i += n
        while v.count > 1, v[0] == 0 { v.removeFirst() }
        return Data(v)
    }
    guard b.first == 0x30 else { return nil }
    i = 1
    guard len() != nil, let n = integer(), let e = integer() else { return nil }
    return (n, e)
}

/// Android TV pairing secret. Returns nil if the code's checksum byte doesn't match (typo).
func pairingSecret(client: (Data, Data), server: (Data, Data), code: String) -> Data? {
    let code = code.trimmingCharacters(in: .whitespaces).uppercased()
    guard code.count == 6, let check = UInt8(code.prefix(2), radix: 16),
          let nonce = Data(hex: String(code.dropFirst(2))) else { return nil }
    var h = SHA256()
    h.update(data: client.0); h.update(data: client.1)
    h.update(data: server.0); h.update(data: server.1)
    h.update(data: nonce)
    let digest = Data(h.finalize())
    return digest.first == check ? digest : nil
}

extension Data {
    init?(hex: String) {
        guard hex.count % 2 == 0 else { return nil }
        var out = Data(), idx = hex.startIndex
        while idx < hex.endIndex {
            let next = hex.index(idx, offsetBy: 2)
            guard let byte = UInt8(hex[idx..<next], radix: 16) else { return nil }
            out.append(byte); idx = next
        }
        self = out
    }
}

// MARK: - TLS connection with varint-framed messages

final class TLSConn {
    private let queue = DispatchQueue(label: "tclremote.tls")
    private var conn: NWConnection!
    private var buffer = Data()
    private(set) var serverKey: SecKey?

    init(host: String, port: UInt16, identity: SecIdentity) {
        let tls = NWProtocolTLS.Options()
        let sec = tls.securityProtocolOptions
        sec_protocol_options_set_local_identity(sec, sec_identity_create(identity)!)
        sec_protocol_options_set_verify_block(sec, { [weak self] _, trust, complete in
            let t = sec_trust_copy_ref(trust).takeRetainedValue()
            if let cert = (SecTrustCopyCertificateChain(t) as? [SecCertificate])?.first {
                self?.serverKey = SecCertificateCopyKey(cert)
            }
            complete(true) // ponytail: TVs use self-signed certs; pin on first use if MITM on LAN matters
        }, queue)
        conn = NWConnection(host: .init(host), port: .init(rawValue: port)!, using: .init(tls: tls))
    }

    func start(timeout: TimeInterval = 6) async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            var done = false
            let finish: (Result<Void, Error>) -> Void = { [conn] r in
                guard !done else { return }
                done = true
                if case .failure = r { conn?.cancel() }
                c.resume(with: r)
            }
            conn.stateUpdateHandler = { state in
                switch state {
                case .ready: finish(.success(()))
                case .failed(let e), .waiting(let e): finish(.failure(e))
                case .cancelled: finish(.failure(TVError.closed))
                default: break
                }
            }
            conn.start(queue: queue)
            queue.asyncAfter(deadline: .now() + timeout) { finish(.failure(TVError.timeout)) }
        }
    }

    func cancel() { conn.cancel() }

    func send(_ payload: Data) async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            conn.send(content: PB.varint(UInt64(payload.count)) + payload, completion: .contentProcessed { err in
                if let err { c.resume(throwing: err) } else { c.resume() }
            })
        }
    }

    func read() async throws -> PBFields {
        while true {
            let b = [UInt8](buffer)
            var i = 0
            if let n = readVarint(b, &i), i + Int(n) <= b.count {
                buffer = Data(b[(i + Int(n))...])
                return pbDecode(Data(b[i..<i + Int(n)]))
            }
            buffer += try await chunk()
        }
    }

    private func chunk() async throws -> Data {
        try await withCheckedThrowingContinuation { c in
            conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isDone, err in
                if let err { c.resume(throwing: err) }
                else if let data, !data.isEmpty { c.resume(returning: data) }
                else if isDone { c.resume(throwing: TVError.closed) }
                else { c.resume(returning: Data()) }
            }
        }
    }
}

// MARK: - Android TV Remote v2 (pairing :6467, control :6466)

@MainActor
final class AndroidTVRemote: TVRemote {
    let host: String
    private var conn: TLSConn?
    private var pairConn: TLSConn?
    private var active = false
    private var imeCounter = 0, fieldCounter = 0
    var onPower: ((Bool) -> Void)?

    static let features = 622 // ping | key | ime | power | volume | app link

    init(host: String) { self.host = host }

    // Pairing: TV shows a 6-char hex code after this returns.
    func startPairing() async throws {
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

    func finishPairing(code: String) async throws {
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

    func cancelPairing() { pairConn?.cancel(); pairConn = nil }

    func connect() async throws {
        if conn != nil, active { return }
        conn?.cancel()
        active = false
        let c = TLSConn(host: host, port: 6466, identity: try ClientIdentity.load())
        conn = c
        try await c.start()
        Task { [weak self] in
            while let msg = try? await c.read() { await self?.handle(msg, on: c) }
            if self?.conn === c { self?.conn = nil; self?.active = false }
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

    func press(_ key: Key) async throws {
        try await send(PB.build { $0.msg(10) { $0.int(1, key.android); $0.int(2, 3) } })
    }

    func type(_ text: String) async throws {
        let end = max(text.count - 1, 0)
        try await send(PB.build { $0.msg(21) {
            $0.int(1, imeCounter); $0.int(2, fieldCounter)
            $0.msg(3) { $0.int(1, 1); $0.msg(2) { $0.int(1, end); $0.int(2, end); $0.string(3, text) } }
        } })
    }

    func apps() async -> [TVApp] {
        [("YouTube", "https://www.youtube.com"), ("Netflix", "https://www.netflix.com/title"),
         ("Prime Video", "https://app.primevideo.com"), ("Disney+", "https://www.disneyplus.com"),
         ("Spotify", "spotify://"), ("Max", "https://play.max.com")].map { TVApp(id: $0.1, name: $0.0) }
    }

    func launch(_ app: TVApp) async throws {
        try await send(PB.build { $0.msg(90) { $0.string(1, app.id) } })
    }
}
