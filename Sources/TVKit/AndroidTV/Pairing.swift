import CryptoKit
import Foundation
import Security

// MARK: - Client certificate (generated once, kept in Application Support)

public enum ClientIdentity {
    static let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("TCLRemote", isDirectory: true)
    private static let pass = "tclremote"
    private static var cached: SecIdentity?

    private static let keychainQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "TCLRemote",
        kSecAttrAccount as String: "client-identity",
    ]

    /// The PKCS#12 blob lives in the Keychain; the on-disk copy is only used to migrate older installs.
    private static func p12Data() throws -> Data {
        var q = keychainQuery
        q[kSecReturnData as String] = true
        var out: CFTypeRef?
        if SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let d = out as? Data { return d }

        let legacy = dir.appendingPathComponent("client.p12")
        let data: Data
        if let d = try? Data(contentsOf: legacy) {
            data = d
        } else {
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            defer { try? FileManager.default.removeItem(at: tmp) }
            data = try generate(in: tmp)
        }
        var add = keychainQuery
        add[kSecValueData as String] = data
        add[kSecAttrLabel as String] = "TCL Remote pairing certificate"
        let status = SecItemAdd(add as CFDictionary, nil)
        guard status == errSecSuccess || status == errSecDuplicateItem else { throw TVError.identity("keychain \(status)") }
        try? FileManager.default.removeItem(at: dir) // drop legacy files once stored
        return data
    }

    /// Deletes the certificate; every Google TV must be paired again afterwards.
    public static func reset() {
        SecItemDelete(keychainQuery as CFDictionary)
        cached = nil
    }

    static func load() throws -> SecIdentity {
        if let cached { return cached }
        let data = try p12Data()
        let opts: [String: Any] = [kSecImportExportPassphrase as String: pass, kSecImportToMemoryOnly as String: true]
        var items: CFArray?
        let status = SecPKCS12Import(data as CFData, opts as CFDictionary, &items)
        guard status == errSecSuccess, let first = (items as? [[String: Any]])?.first,
              let id = first[kSecImportItemIdentity as String] else { throw TVError.identity("import \(status)") }
        cached = (id as! SecIdentity)
        return cached!
    }

    // ponytail: shells out to the system LibreSSL instead of hand-writing X.509 DER.
    private static func generate(in tmp: URL) throws -> Data {
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        let key = tmp.appendingPathComponent("key.pem").path, cert = tmp.appendingPathComponent("cert.pem").path
        let p12 = tmp.appendingPathComponent("client.p12")
        try openssl(["req", "-x509", "-newkey", "rsa:2048", "-keyout", key, "-out", cert, "-days", "3650", "-nodes", "-subj", "/CN=atvremote"])
        try openssl(["pkcs12", "-export", "-inkey", key, "-in", cert, "-out", p12.path, "-passout", "pass:\(pass)",
                     "-certpbe", "PBE-SHA1-3DES", "-keypbe", "PBE-SHA1-3DES"])
        return try Data(contentsOf: p12)
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
