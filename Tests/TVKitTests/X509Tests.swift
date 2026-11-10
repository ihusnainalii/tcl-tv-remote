import Security
import XCTest
@testable import TVKit

/// The native certificate builder used on iOS, checked with the system's own certificate parser.
final class X509Tests: XCTestCase {
    func testSelfSignedCertificateIsValidAndSignedByTheKey() throws {
        var error: Unmanaged<CFError>?
        let attrs: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeRSA, kSecAttrKeySizeInBits as String: 2048]
        let privateKey = try XCTUnwrap(SecKeyCreateRandomKey(attrs as CFDictionary, &error))
        let publicKey = try XCTUnwrap(SecKeyCopyPublicKey(privateKey))
        let pkcs1 = try XCTUnwrap(SecKeyCopyExternalRepresentation(publicKey, &error) as Data?)

        var signed = Data()
        let der = try X509.selfSigned(commonName: "atvremote", publicKeyPKCS1: pkcs1) { tbs in
            signed = tbs
            return try XCTUnwrap(SecKeyCreateSignature(privateKey, .rsaSignatureMessagePKCS1v15SHA256, tbs as CFData, &error) as Data?)
        }

        let cert = try XCTUnwrap(SecCertificateCreateWithData(nil, der as CFData), "the system parses it")
        XCTAssertEqual(SecCertificateCopySubjectSummary(cert) as String?, "atvremote")
        let certKey = try XCTUnwrap(SecCertificateCopyKey(cert))
        XCTAssertEqual(rsaComponents(certKey)?.0, rsaComponents(publicKey)?.0, "certificate carries our public key")

        // The signature at the end of the certificate verifies against the to-be-signed part.
        let sig = try XCTUnwrap(SecKeyCreateSignature(privateKey, .rsaSignatureMessagePKCS1v15SHA256, signed as CFData, &error) as Data?)
        XCTAssertEqual(der.suffix(sig.count), sig, "PKCS#1 v1.5 is deterministic: the certificate ends with this signature")
        XCTAssertTrue(SecKeyVerifySignature(publicKey, .rsaSignatureMessagePKCS1v15SHA256, signed as CFData, sig as CFData, &error))
    }

    func testDERLengthsAndIntegers() {
        XCTAssertEqual(X509.length(5), Data([0x05]))
        XCTAssertEqual(X509.length(0x80), Data([0x81, 0x80]))
        XCTAssertEqual(X509.length(0x1234), Data([0x82, 0x12, 0x34]))
        XCTAssertEqual(X509.integer(Data([0x80])), Data([0x02, 0x02, 0x00, 0x80]), "high bit gets a zero prefix")
        XCTAssertEqual(X509.integer(Data([0x01])), Data([0x02, 0x01, 0x01]))
    }
}
