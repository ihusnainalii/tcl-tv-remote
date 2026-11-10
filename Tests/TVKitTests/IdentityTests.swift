import Security
import XCTest
@testable import TVKit

/// The pairing certificate store, using a test-only Keychain item and folder (never the user's).
final class IdentityTests: XCTestCase {
    var savedService = "", savedDir = URL(fileURLWithPath: "/")

    override func setUp() {
        savedService = ClientIdentity.service
        savedDir = ClientIdentity.dir
        ClientIdentity.service = "TCLRemote-Tests-\(UUID().uuidString)"
        ClientIdentity.dir = FileManager.default.temporaryDirectory.appendingPathComponent("TCLRemoteTests-\(UUID())")
        ClientIdentity.reset()
    }

    override func tearDown() {
        ClientIdentity.reset()
        try? FileManager.default.removeItem(at: ClientIdentity.dir)
        ClientIdentity.service = savedService
        ClientIdentity.dir = savedDir
    }

    func testGeneratesStoresCachesAndResets() async throws {
        let first = try await ClientIdentity.loadOffMain()
        XCTAssertTrue(first === (try ClientIdentity.load()), "cached after the first load")
        XCTAssertEqual(TestIdentity.rsa(first).0.count, 256, "RSA-2048")

        ClientIdentity.dropCache()
        let reloaded = try ClientIdentity.load() // read back from the Keychain item
        XCTAssertEqual(TestIdentity.rsa(reloaded).0, TestIdentity.rsa(first).0)

        ClientIdentity.reset() // deletes the item: the next load makes a new certificate
        let fresh = try ClientIdentity.load()
        XCTAssertNotEqual(TestIdentity.rsa(fresh).0, TestIdentity.rsa(first).0)
    }

    func testMigratesLegacyFile() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tmp) }
        let legacy = try ClientIdentity.generate(in: tmp)
        try FileManager.default.createDirectory(at: ClientIdentity.dir, withIntermediateDirectories: true)
        try legacy.write(to: ClientIdentity.dir.appendingPathComponent("client.p12"))

        _ = try ClientIdentity.load()
        XCTAssertFalse(FileManager.default.fileExists(atPath: ClientIdentity.dir.path), "legacy folder removed after migration")
    }
}
