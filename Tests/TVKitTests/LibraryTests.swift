import XCTest
@testable import TVKit

final class LibraryTests: XCTestCase {
    let living = TV(name: "Living Room", host: "10.0.0.5", kind: .androidTV)
    let bedroom = TV(name: "Bedroom", host: "10.0.0.6", kind: .roku)
    let yt = TVApp(id: "yt", name: "YouTube"), nf = TVApp(id: "nf", name: "Netflix"), sp = TVApp(id: "sp", name: "Spotify")

    func testRememberOrdersByRecencyAndKeepsExtras() {
        var lib = TVLibrary()
        lib.remember(living, at: .init(timeIntervalSince1970: 1))
        lib.rename(living.id, to: "  Lounge ")
        lib.remember(bedroom, at: .init(timeIntervalSince1970: 2))
        lib.remember(living, at: .init(timeIntervalSince1970: 3))
        XCTAssertEqual(lib.tvs.map(\.id), [living.id, bedroom.id])
        XCTAssertEqual(lib.tvs[0].name, "Lounge", "nickname trimmed and kept across remember()")
    }

    func testFavoritesSortFirstAndWinAutoConnect() {
        var lib = TVLibrary()
        lib.remember(bedroom); lib.remember(living)
        XCTAssertEqual(lib.autoConnectPick?.id, living.id)
        lib.toggleFavorite(bedroom.id)
        XCTAssertEqual(lib.sorted.first?.id, bedroom.id)
        XCTAssertEqual(lib.autoConnectPick?.id, bedroom.id)
    }

    func testFollowMovedTV() {
        var lib = TVLibrary()
        lib.remember(living)
        let moved = TV(name: "Living Room", host: "10.0.0.99", kind: .androidTV)
        XCTAssertEqual(lib.follow(moved), living.id)
        XCTAssertEqual(lib.tvs[0].tv.host, "10.0.0.99")
        XCTAssertNil(lib.follow(bedroom), "unknown TV is not a move")
        XCTAssertEqual(lib.unsaved([moved, bedroom]), [bedroom])
    }

    func testAppOrderingFavoritesThenRecentsThenRest() {
        var lib = TVLibrary()
        lib.remember(living)
        lib.recordLaunch(sp, on: living.id)
        lib.toggleFavoriteApp(nf, on: living.id)
        let custom = TVApp(id: "https://twitch.tv", name: "Twitch")
        lib.addCustomApp(custom, on: living.id)
        XCTAssertEqual(lib.apps(for: living.id, tvApps: [yt, nf, sp]).map(\.id), ["nf", "sp", custom.id, "yt"])
        XCTAssertTrue(lib.isCustomApp(custom, on: living.id))
        lib.removeCustomApp(custom, on: living.id)
        XCTAssertFalse(lib.apps(for: living.id, tvApps: [yt]).contains(custom))
    }

    func testRecentAppsCappedAtFive() {
        var lib = TVLibrary()
        lib.remember(living)
        for i in 0..<8 { lib.recordLaunch(TVApp(id: "\(i)", name: "\(i)"), on: living.id) }
        XCTAssertEqual(lib.tvs[0].recentApps, ["7", "6", "5", "4", "3"])
    }

    func testRepositoryRoundTrip() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "TVKitTests-\(UUID())"))
        let repo = UserDefaultsTVRepository(defaults: defaults)
        var lib = TVLibrary(); lib.remember(living); lib.toggleFavorite(living.id)
        repo.save(lib.tvs)
        XCTAssertEqual(repo.load(), lib.tvs)
    }

    @MainActor func testVolumeStepperWalksAndRetargets() async throws {
        var pressed: [Key] = []
        let stepper = VolumeStepper(stepDelay: .milliseconds(1)) { pressed.append($0) }
        stepper.move(from: 10, to: 13)
        stepper.move(from: 10, to: 12) // retarget mid-walk
        for _ in 0..<200 where stepper.isActive { try await Task.sleep(for: .milliseconds(2)) }
        XCTAssertEqual(pressed.filter { $0 == .volUp }.count - pressed.filter { $0 == .volDown }.count, 2)
        XCTAssertFalse(stepper.isActive)
    }
}
