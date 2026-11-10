import Security
import XCTest
@testable import TVKit

/// Pairing and remote control against a fake Google TV on localhost.
@MainActor
final class AndroidTVTests: XCTestCase {
    var tv: FakeAndroidTV!
    var id: SecIdentity!

    override func setUp() async throws {
        id = try TestIdentity.make()
        tv = try FakeAndroidTV(identity: id)
        try await tv.start()
    }

    override func tearDown() async throws { tv.stop() }

    func remote() -> AndroidTVRemote {
        let identity = id!
        return AndroidTVRemote(host: "127.0.0.1", port: tv.remotePort, pairingPort: tv.pairingPort) { identity }
    }

    /// The code the TV would show: checksum byte of the secret + the nonce.
    func validCode(nonce: String = "ABCD") -> String {
        let rsa = TestIdentity.rsa(id) // fake TV and client share the identity
        for check in 0...255 {
            let code = String(format: "%02X", check) + nonce
            if pairingSecret(client: rsa, server: rsa, code: code) != nil { return code }
        }
        fatalError("no checksum")
    }

    func testPairingSucceeds() async throws {
        let r = remote()
        try await r.startPairing()
        XCTAssertEqual(tv.pairingMessages.count, 3, "request, options, configuration")
        XCTAssertEqual(tv.pairingMessages[0].msg(10).flatMap { f -> String? in
            if case let .bytes(d)? = f[1]?.first { return String(data: d, encoding: .utf8) } else { return nil }
        }, "atvremote")
        try await r.finishPairing(code: validCode())
        XCTAssertNotNil(tv.pairingMessages.last?[40], "secret sent")
    }

    func testPairingWithTypoIsRejectedLocally() async throws {
        let r = remote()
        try await r.startPairing()
        let good = validCode()
        let wrongCheck = String(format: "%02X", (Int(good.prefix(2), radix: 16)! + 1) % 256) + good.dropFirst(2)
        do { try await r.finishPairing(code: wrongCheck); XCTFail("expected badCode") } catch TVError.badCode {}
        r.cancelPairing()
    }

    func testPairingRejectedByTV() async throws {
        tv.rejectSecret = true
        let r = remote()
        try await r.startPairing()
        do { try await r.finishPairing(code: validCode()); XCTFail("expected badCode") } catch TVError.badCode {}
    }

    func testPairingStepRejected() async throws {
        tv.rejectPairingSteps = true
        do { try await remote().startPairing(); XCTFail("expected rejection") } catch TVError.rejected(let s) {
            XCTAssertEqual(s, "status 402")
        }
    }

    func testFinishWithoutStartFails() async {
        do {
            try await remote().finishPairing(code: "ABCDEF")
            XCTFail("finishing without starting should fail")
        } catch TVError.closed {} catch { XCTFail("unexpected \(error)") }
    }

    func testConnectHandshakeKeysTextAppsAndState() async throws {
        let r = remote()
        var power: Bool?, volume: TVVolume?, disconnected = false
        r.onPower = { power = $0 }
        r.onVolume = { volume = $0 }
        r.onDisconnect = { disconnected = true }

        try await r.connect()
        try await r.connect() // already active: no-op
        let configured = await eventually { self.tv.messages.contains { $0.msg(1)?.int(1) == AndroidTVRemote.features } }
        XCTAssertTrue(configured, "configure reply with feature flags")
        XCTAssertTrue(tv.messages.contains { $0.msg(2)?.int(1) == AndroidTVRemote.features }, "set_active reply")

        tv.push(PB.build { $0.msg(8) { $0.int(1, 42) } })                                 // ping
        tv.push(PB.build { $0.msg(40) { $0.int(1, 1) } })                                  // powered on
        tv.push(PB.build { $0.msg(50) { $0.int(6, 100); $0.int(7, 18); $0.int(8, 1) } })   // volume 18, muted
        let stateArrived = await eventually { power == true && volume != nil }
        XCTAssertTrue(stateArrived)
        XCTAssertEqual(volume, TVVolume(level: 18, max: 100, muted: true))
        let pong = await eventually { self.tv.messages.contains { $0.msg(9)?.int(1) == 42 } }
        XCTAssertTrue(pong, "ping answered")

        try await r.press(.home)
        try await r.type("Ab1")
        try await r.launch(TVApp(id: "https://www.youtube.com", name: "YouTube"))
        let keys = await eventually { self.keyCodes().count >= 4 && self.appLinks() == ["https://www.youtube.com"] }
        XCTAssertTrue(keys)
        XCTAssertEqual(keyCodes(), [3, 29, 30, 8], "home, a, b, 1")
        let apps = await r.apps()
        XCTAssertEqual(apps, AppCatalog.featured)

        tv.dropClients()
        let dropped = await eventually { disconnected }
        XCTAssertTrue(dropped, "onDisconnect fires when the TV goes away")

        // Next command reconnects transparently.
        try await r.press(.back)
        let resent = await eventually { self.keyCodes().last == 4 }
        XCTAssertTrue(resent)
    }

    func testConnectTimesOutWithoutHandshake() async {
        tv.skipHandshake = true
        do { try await remote().connect(); XCTFail("expected timeout") } catch TVError.timeout {} catch { XCTFail("\(error)") }
    }

    func testConnectToClosedPortFails() async {
        let identity = id!
        let r = AndroidTVRemote(host: "127.0.0.1", port: 1, pairingPort: 1) { identity }
        do { try await r.connect(); XCTFail("expected failure") } catch {}
    }

    // MARK: helpers

    func keyCodes() -> [Int] { tv.messages.compactMap { $0.msg(10)?.int(1) } }
    func appLinks() -> [String] {
        tv.messages.compactMap { m in
            if case let .bytes(d)? = m.msg(90)?[1]?.first { return String(data: d, encoding: .utf8) } else { return nil }
        }
    }
}
