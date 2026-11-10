import CryptoKit
import Foundation
import Security

// MARK: - Client certificate (generated once, kept in Application Support)

public enum ClientIdentity {
    // Overridable so tests use their own Keychain item and folder, never the user's pairing.
    static var dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("TCLRemote", isDirectory: true)
    static var service = "TCLRemote"
    private static let pass = "tclremote"
    private static var cached: SecIdentity?

    /// Forgets the in-memory copy only (tests use it to exercise the Keychain read path).
    static func dropCache() { cached = nil }

    /// Keychain reads can block on a macOS permission prompt, so never do them on the main thread.
    static func loadOffMain() async throws -> SecIdentity {
        try await Task.detached(priority: .userInitiated) { try load() }.value
    }

    static func load() throws -> SecIdentity {
        if let cached { return cached }
        let id = try loadOrCreate()
        cached = id
        return id
    }

#if os(macOS)
    // macOS: a PKCS#12 blob (made with the system's LibreSSL) stored as a Keychain item and
    // imported in memory, so it works for ad-hoc signed builds without Keychain entitlements.

    private static var keychainQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: "client-identity"]
    }

    /// Deletes the certificate; every Google TV must be paired again afterwards.
    public static func reset() {
        SecItemDelete(keychainQuery as CFDictionary)
        cached = nil
    }

    private static func loadOrCreate() throws -> SecIdentity {
        let data = try p12Data()
        let opts: [String: Any] = [kSecImportExportPassphrase as String: pass, kSecImportToMemoryOnly as String: true]
        var items: CFArray?
        let status = SecPKCS12Import(data as CFData, opts as CFDictionary, &items)
        guard status == errSecSuccess, let first = (items as? [[String: Any]])?.first,
              let value = first[kSecImportItemIdentity as String] else { throw TVError.identity("import \(status)") }
        // SecIdentity is a CF type, so a conditional cast can't be written; this always succeeds.
        return value as! SecIdentity // swiftlint:disable:this force_cast
    }

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

    // ponytail: shells out to the system LibreSSL on macOS; iOS uses the native X509 builder.
    static func generate(in tmp: URL) throws -> Data {
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        let key = tmp.appendingPathComponent("key.pem").path, cert = tmp.appendingPathComponent("cert.pem").path
        let p12 = tmp.appendingPathComponent("client.p12")
        try openssl(["req", "-x509", "-newkey", "rsa:2048", "-keyout", key, "-out", cert,
                     "-days", "3650", "-nodes", "-subj", "/CN=atvremote"])
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
#else
    // iOS / iPadOS: a permanent RSA key plus a natively built certificate in the Keychain;
    // the system pairs them into an identity.

    private static var keyTag: Data { Data("\(service).client-key".utf8) }

    public static func reset() {
        SecItemDelete([kSecClass as String: kSecClassCertificate, kSecAttrLabel as String: service] as CFDictionary)
        SecItemDelete([kSecClass as String: kSecClassKey, kSecAttrApplicationTag as String: keyTag] as CFDictionary)
        cached = nil
    }

    private static func loadOrCreate() throws -> SecIdentity {
        if let id = findIdentity() { return id }
        reset() // clear any half-written key or certificate
        var error: Unmanaged<CFError>?
        let attrs: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPrivateKeyAttrs as String: [kSecAttrIsPermanent as String: true,
                                            kSecAttrApplicationTag as String: keyTag,
                                            kSecAttrLabel as String: service],
        ]
        guard let privateKey = SecKeyCreateRandomKey(attrs as CFDictionary, &error),
              let publicKey = SecKeyCopyPublicKey(privateKey),
              let pkcs1 = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            throw TVError.identity("key generation")
        }
        let der = try X509.selfSigned(commonName: "atvremote", publicKeyPKCS1: pkcs1) { tbs in
            guard let sig = SecKeyCreateSignature(privateKey, .rsaSignatureMessagePKCS1v15SHA256, tbs as CFData, &error)
            else { throw TVError.identity("signing") }
            return sig as Data
        }
        guard let cert = SecCertificateCreateWithData(nil, der as CFData) else { throw TVError.identity("certificate") }
        let add: [String: Any] = [kSecClass as String: kSecClassCertificate, kSecValueRef as String: cert,
                                  kSecAttrLabel as String: service]
        let status = SecItemAdd(add as CFDictionary, nil)
        guard status == errSecSuccess || status == errSecDuplicateItem, let id = findIdentity() else {
            throw TVError.identity("keychain \(status)")
        }
        return id
    }

    private static func findIdentity() -> SecIdentity? {
        let q: [String: Any] = [kSecClass as String: kSecClassIdentity, kSecAttrLabel as String: service,
                                kSecReturnRef as String: true]
        var out: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let out else { return nil }
        return (out as! SecIdentity) // swiftlint:disable:this force_cast
    }
#endif
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
