import XCTest
@testable import TVKit

/// Pure parsing and mapping code that doesn't need a TV.
final class ParsingTests: XCTestCase {
    func testRokuAppsParsing() {
        let xml = #"<apps><app id="12" type="appl" version="5.1">Netflix</app><app id="837" type="appl">YouTube &amp; Kids</app></apps>"#
        let apps = RokuRemote.parseApps(xml, base: "http://10.0.0.7:8060/")
        XCTAssertEqual(apps.map(\.id), ["12", "837"])
        XCTAssertEqual(apps[1].name, "YouTube & Kids")
        XCTAssertEqual(apps[0].icon?.absoluteString, "http://10.0.0.7:8060/query/icon/12")
    }

    func testRokuNamePrefersUserName() {
        let xml = "<device-info><model-name>TCL 55S</model-name><user-device-name>Den</user-device-name></device-info>"
        XCTAssertEqual(RokuRemote.parseName(xml), "Den")
        XCTAssertEqual(RokuRemote.parseName("<model-name>TCL 55S</model-name><user-device-name></user-device-name>"), "TCL 55S")
        XCTAssertNil(RokuRemote.parseName("<device-info/>"))
    }

    func testEveryKeyMapsOrIsExplicitlyUnsupportedOnRoku() {
        let unsupported: Set<Key> = [.guide, .captions, .stop]
        for k in Key.allCases where !unsupported.contains(k) { XCTAssertFalse(k.roku.isEmpty, "\(k) has no Roku key") }
        XCTAssertEqual(Key.n5.roku, "Lit_5")
        XCTAssertEqual(Key.hdmi2.label, "HDMI 2")
    }

    @MainActor func testRemoteFactoryPicksDriverAndCapabilities() {
        let google = RemoteFactory.make(for: TV(name: "a", host: "10.0.0.1", kind: .androidTV))
        let roku = RemoteFactory.make(for: TV(name: "b", host: "10.0.0.2", kind: .roku))
        XCTAssertTrue(google is PairingCapable && google is StateReporting)
        XCTAssertFalse(roku is PairingCapable)
    }

    func testAppCatalogHasUniqueLinksAndFeaturedFirst() {
        XCTAssertEqual(Set(AppCatalog.googleTV.map(\.id)).count, AppCatalog.googleTV.count)
        XCTAssertEqual(Array(AppCatalog.googleTV.prefix(AppCatalog.featured.count)), AppCatalog.featured)
    }

    func testAppStoreArtworkParsing() {
        let json = Data(#"{"resultCount":1,"results":[{"artworkUrl512":"https://is1.example/icon.png"}]}"#.utf8)
        XCTAssertEqual(AppIconResolver.artwork(in: json)?.absoluteString, "https://is1.example/icon.png")
        XCTAssertNil(AppIconResolver.artwork(in: Data(#"{"results":[]}"#.utf8)))
    }
}
