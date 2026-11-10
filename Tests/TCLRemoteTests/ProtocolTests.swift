import XCTest
@testable import TCLRemote

final class ProtocolTests: XCTestCase {
    func testProtobufRoundTrip() {
        let data = PB.build { $0.int(1, 300); $0.msg(10) { $0.int(1, 26); $0.string(2, "hi") } }
        let f = pbDecode(data)
        XCTAssertEqual(f.int(1), 300)
        XCTAssertEqual(f.msg(10)?.int(1), 26)
        guard case let .bytes(s)? = f.msg(10)?[2]?.first else { return XCTFail() }
        XCTAssertEqual(String(data: s, encoding: .utf8), "hi")
    }

    func testEveryKeyHasAndroidCode() {
        for k in Key.allCases { XCTAssertNotEqual(k.android, 0, "\(k) unmapped") }
        XCTAssertEqual(Key.n0.android, 7); XCTAssertEqual(Key.next.android, 87); XCTAssertNil(Key.next.digit)
    }

    func testOldSavedTVsStillDecode() throws {
        let old = #"[{"tv":{"name":"Living Room","host":"10.0.0.5","kind":"Google TV"},"lastUsed":0}]"#
        let k = try JSONDecoder().decode([KnownTV].self, from: Data(old.utf8))[0]
        XCTAssertEqual(k.name, "Living Room")
        XCTAssertNil(k.favorite)
        var renamed = k; renamed.nickname = "Bedroom"
        XCTAssertEqual(renamed.name, "Bedroom")
    }

    func testRSAComponentsStripsLeadingZero() {
        // SEQUENCE { INTEGER 00 C0 FF, INTEGER 01 00 01 }
        let der = Data([0x30, 0x0A, 0x02, 0x03, 0x00, 0xC0, 0xFF, 0x02, 0x03, 0x01, 0x00, 0x01])
        let (n, e) = rsaComponents(pkcs1: der)!
        XCTAssertEqual(n, Data([0xC0, 0xFF]))
        XCTAssertEqual(e, Data([0x01, 0x00, 0x01]))
    }

    func testPairingSecret() {
        // Vector from python: sha256(client_n + client_e + server_n + server_e + nonce)
        let client = (Data(hex: "C0FFEE1234")!, Data(hex: "010001")!)
        let server = (Data(hex: "BADA55")!, Data(hex: "010001")!)
        let secret = pairingSecret(client: client, server: server, code: "76abcd")
        XCTAssertEqual(secret, Data(hex: "7658E7B6D6D3DA270AFEB5E5857ECE9AF033BBCE14EC271AEF5AFF378EA4AD7A".lowercased()))
        XCTAssertNil(pairingSecret(client: client, server: server, code: "77ABCD"), "checksum byte must be verified")
    }
}
