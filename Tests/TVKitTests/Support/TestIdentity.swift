import Foundation
import Security
@testable import TVKit

/// A throwaway self-signed identity for tests, imported in memory only (never into the Keychain).
enum TestIdentity {
    nonisolated(unsafe) private static var cached: SecIdentity?

    static func make() throws -> SecIdentity {
        if let cached { return cached }
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tmp) }
        let data = try ClientIdentity.generate(in: tmp)
        let opts: [String: Any] = [kSecImportExportPassphrase as String: "tclremote", kSecImportToMemoryOnly as String: true]
        var items: CFArray?
        guard SecPKCS12Import(data as CFData, opts as CFDictionary, &items) == errSecSuccess,
              let id = (items as? [[String: Any]])?.first?[kSecImportItemIdentity as String] else {
            throw TVError.identity("test identity")
        }
        cached = (id as! SecIdentity)
        return cached!
    }

    static func rsa(_ id: SecIdentity) -> (Data, Data) {
        var cert: SecCertificate?
        SecIdentityCopyCertificate(id, &cert)
        return rsaComponents(SecCertificateCopyKey(cert!)!)!
    }
}

/// Polls until a condition holds (async network callbacks), failing after `timeout`.
func eventually(_ timeout: Duration = .seconds(5), _ condition: @escaping () -> Bool) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while ContinuousClock.now < deadline {
        if condition() { return true }
        try? await Task.sleep(for: .milliseconds(20))
    }
    return condition()
}
