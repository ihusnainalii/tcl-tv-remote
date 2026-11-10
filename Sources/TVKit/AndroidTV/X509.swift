import Foundation
import Security

/// Builds a minimal self-signed X.509 v3 certificate (RSA, SHA-256), which is all Android TV pairing
/// needs. Used where there's no `openssl` command (iOS); DER is assembled by hand.
enum X509 {
    /// - Parameters:
    ///   - publicKeyPKCS1: the RSA public key as PKCS#1 `RSAPublicKey` DER (what `SecKeyCopyExternalRepresentation` returns)
    ///   - sign: signs the to-be-signed bytes with the matching private key (RSA PKCS#1 v1.5, SHA-256)
    static func selfSigned(commonName: String, publicKeyPKCS1: Data, validFor years: Int = 10, now: Date = .now,
                           sign: (Data) throws -> Data) rethrows -> Data {
        let sha256WithRSA = sequence(oid([0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0B]) + null)
        let rsaEncryption = sequence(oid([0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01]) + null)
        let name = sequence(set(sequence(oid([0x55, 0x04, 0x03]) + tlv(0x0C, Data(commonName.utf8)))))
        let notAfter = Calendar(identifier: .gregorian).date(byAdding: .year, value: years, to: now) ?? now

        var serial = Data((0..<8).map { _ in UInt8.random(in: 0...255) })
        serial[0] &= 0x7F // keep it positive
        serial[0] |= 0x01 // and without a leading zero byte

        let tbs = sequence(
            tlv(0xA0, integer(Data([0x02])))                     // version: v3
            + integer(serial)
            + sha256WithRSA
            + name                                               // issuer
            + sequence(utcTime(now) + utcTime(notAfter))         // validity
            + name                                               // subject (self-signed)
            + sequence(rsaEncryption + bitString(publicKeyPKCS1)) // subjectPublicKeyInfo
        )
        let signature = try sign(tbs)
        return sequence(tbs + sha256WithRSA + bitString(signature))
    }

    // MARK: DER encoding

    static func length(_ n: Int) -> Data {
        if n < 0x80 { return Data([UInt8(n)]) }
        var bytes: [UInt8] = []
        var v = n
        while v > 0 { bytes.insert(UInt8(v & 0xFF), at: 0); v >>= 8 }
        return Data([0x80 | UInt8(bytes.count)] + bytes)
    }

    static func tlv(_ tag: UInt8, _ value: Data) -> Data { Data([tag]) + length(value.count) + value }
    static func sequence(_ content: Data) -> Data { tlv(0x30, content) }
    static func set(_ content: Data) -> Data { tlv(0x31, content) }
    static func oid(_ bytes: [UInt8]) -> Data { tlv(0x06, Data(bytes)) }
    static let null = Data([0x05, 0x00])
    static func bitString(_ bytes: Data) -> Data { tlv(0x03, Data([0x00]) + bytes) }

    static func integer(_ bytes: Data) -> Data {
        // DER integers are signed: prefix 0x00 when the high bit is set.
        tlv(0x02, (bytes.first ?? 0) & 0x80 != 0 ? Data([0x00]) + bytes : bytes)
    }

    static func utcTime(_ date: Date) -> Data {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyMMddHHmmss'Z'"
        return tlv(0x17, Data(f.string(from: date).utf8))
    }
}
