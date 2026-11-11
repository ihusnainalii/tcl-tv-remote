import XCTest
@testable import TVKit

/// Roku ECP, update checks and icon lookups against stubbed HTTP.
final class HTTPTests: XCTestCase {
    override func setUp() { StubURLProtocol.install() }
    override func tearDown() { StubURLProtocol.uninstall() }

    // MARK: Roku

    func testRokuCommands() async throws {
        let roku = RokuRemote(host: "10.0.0.7")
        StubURLProtocol.on("/query/device-info", "<device-info><user-device-name>Den</user-device-name></device-info>")
        StubURLProtocol.on("/query/apps", #"<apps><app id="12">Netflix</app></apps>"#)
        for path in ["/keypress/Home", "/keypress/Lit_h", "/keypress/Lit_ ", "/keypress/Lit_!", "/launch/12"] { // URL.path is decoded
            StubURLProtocol.on("POST \(path)")
        }

        try await roku.connect()
        try await roku.press(.home)
        try await roku.type("h !")
        let apps = await roku.apps()
        XCTAssertEqual(apps.map(\.name), ["Netflix"])
        try await roku.launch(apps[0])
        let name = await RokuRemote.name(host: "10.0.0.7")
        XCTAssertEqual(name, "Den")

        XCTAssertTrue(StubURLProtocol.requests.contains("POST /keypress/Home"))
        XCTAssertTrue(StubURLProtocol.requests.contains("POST /keypress/Lit_ "), "space sent as an encoded literal")
        XCTAssertTrue(StubURLProtocol.requests.contains("POST /launch/12"))
    }

    func testRokuErrors() async {
        let roku = RokuRemote(host: "10.0.0.7")
        StubURLProtocol.on("POST /keypress/Up", status: 503)
        do {
            try await roku.press(.up)
            XCTFail("HTTP 503 should be an error")
        } catch TVError.rejected(let s) { XCTAssertEqual(s, "HTTP 503") } catch { XCTFail("unexpected \(error)") }
        do {
            try await roku.press(.guide)
            XCTFail("Roku has no Guide key")
        } catch TVError.unsupported(let k) { XCTAssertEqual(k, "Guide") } catch { XCTFail("unexpected \(error)") }
        StubURLProtocol.failAll = true
        let apps = await roku.apps()
        XCTAssertEqual(apps, [], "unreachable TV lists no apps")
        let name = await RokuRemote.name(host: "10.0.0.7")
        XCTAssertNil(name)
    }

    // MARK: Update check

    func testUpdateCheck() async {
        let path = "/repos/\(UpdateCheck.repo)/releases/latest"
        StubURLProtocol.on(path, #"{"tag_name":"v9.0.0","html_url":"https://github.com/x/releases/v9"}"#)
        var result = await UpdateCheck.run(current: "1.0")
        XCTAssertEqual(result, .available("9.0.0", URL(string: "https://github.com/x/releases/v9")!))

        StubURLProtocol.on(path, #"{"tag_name":"v1.0","html_url":"https://github.com/x"}"#)
        result = await UpdateCheck.run(current: "1.0")
        XCTAssertEqual(result, .upToDate)

        StubURLProtocol.on(path, status: 404, "{}")
        result = await UpdateCheck.run(current: "1.0")
        XCTAssertEqual(result, .failed("No releases published yet"))

        StubURLProtocol.failAll = true
        result = await UpdateCheck.run(current: "1.0")
        XCTAssertEqual(result, .failed("Couldn't reach GitHub"))
    }

    // MARK: Icons

    func testIconResolution() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "icons-\(UUID())"))
        let resolver = AppIconResolver(defaults: defaults)
        let art = #"{"results":[{"artworkUrl512":"https://img.example/yt.png"}]}"#
        StubURLProtocol.on("/lookup", art)
        StubURLProtocol.on("/search", #"{"results":[{"artworkUrl100":"https://img.example/twitch.png"}]}"#)

        let own = TVApp(id: "12", name: "Netflix", icon: URL(string: "http://tv/icon/12"))
        let tvIcon = await resolver.icon(for: own)
        XCTAssertEqual(tvIcon?.absoluteString, "http://tv/icon/12", "the TV's own icon wins")

        let yt = await resolver.icon(for: TVApp(id: "https://www.youtube.com", name: "YouTube"))
        XCTAssertEqual(yt?.absoluteString, "https://img.example/yt.png")
        XCTAssertTrue(StubURLProtocol.requests.contains { $0.contains("bundleId=com.google.ios.youtube") }, "exact bundle lookup")

        let twitch = await resolver.icon(for: TVApp(id: "twitch://home", name: "Twitch"))
        XCTAssertEqual(twitch?.absoluteString, "https://img.example/twitch.png", "name search fallback")

        let before = StubURLProtocol.requests.count
        let cached = await AppIconResolver(defaults: defaults).icon(for: TVApp(id: "x", name: "YouTube"))
        XCTAssertEqual(cached?.absoluteString, "https://img.example/yt.png")
        XCTAssertEqual(StubURLProtocol.requests.count, before, "served from the persisted cache")

        StubURLProtocol.on("/search", #"{"results":[]}"#)
        let missing = await resolver.icon(for: TVApp(id: "y", name: "Nothing"))
        XCTAssertNil(missing)
        let missAgain = await resolver.icon(for: TVApp(id: "y", name: "Nothing"))
        XCTAssertNil(missAgain, "misses are cached too")

        StubURLProtocol.failAll = true
        let offline = await AppIconResolver(defaults: try XCTUnwrap(UserDefaults(suiteName: "icons-\(UUID())")))
            .icon(for: TVApp(id: "z", name: "Offline"))
        XCTAssertNil(offline)
    }

    // MARK: Errors

    func testErrorMessages() {
        let all: [TVError] = [.closed, .timeout, .rejected("x"), .badCode, .identity("y"), .unsupported("Guide")]
        for e in all { XCTAssertFalse(e.errorDescription?.isEmpty ?? true) }
        XCTAssertEqual(TVError.unsupported("Guide").errorDescription, "Guide isn't available on this TV")
    }
}
