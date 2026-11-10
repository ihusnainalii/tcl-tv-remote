import XCTest
@testable import TVKit

/// Integration test against a real Google/Android TV. Skipped unless TV_HOST is set:
///   TV_HOST=192.168.1.8 TV_CODE_FILE=/tmp/code.txt swift test --filter LiveTVTests
/// If the Mac isn't paired yet, the TV shows a code; write it to TV_CODE_FILE to continue.
/// stderr is unbuffered, so progress shows up while the test waits.
private func log(_ s: String) { FileHandle.standardError.write(Data((s + "\n").utf8)) }

@MainActor
final class LiveTVTests: XCTestCase {
    func testPairConnectAndPress() async throws {
        guard let host = ProcessInfo.processInfo.environment["TV_HOST"] else { throw XCTSkip("TV_HOST not set") }
        let tv = AndroidTVRemote(host: host)
        var volume: (Int, Int, Bool)?
        var power: Bool?
        tv.onVolume = { volume = ($0, $1, $2) }
        tv.onPower = { power = $0 }

        do {
            try await tv.connect()
            log("LIVE: already paired, connected")
        } catch {
            log("LIVE: connect failed (\(error.localizedDescription)); pairing")
            try await tv.startPairing()
            log("LIVE: code is on the TV, waiting for TV_CODE_FILE")
            let codeFile = ProcessInfo.processInfo.environment["TV_CODE_FILE"] ?? "/tmp/tv-code.txt"
            var code: String?
            for _ in 0..<300 where code == nil {
                code = (try? String(contentsOfFile: codeFile, encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines)
                if code?.isEmpty == true { code = nil }
                try await Task.sleep(for: .seconds(1))
            }
            try await tv.finishPairing(code: try XCTUnwrap(code, "no code"))
            log("LIVE: paired")
            try await tv.connect()
            log("LIVE: connected")
        }

        try await Task.sleep(for: .seconds(1))
        log("LIVE: power=\(power.map(String.init) ?? "unknown") volume=\(volume.map { "\($0.0)/\($0.1) muted=\($0.2)" } ?? "unknown")")

        // Harmless round trip: volume up then down.
        try await tv.press(.volUp)
        try await Task.sleep(for: .milliseconds(700))
        log("LIVE: after volUp volume=\(volume.map { "\($0.0)/\($0.1)" } ?? "unknown")")
        try await tv.press(.volDown)
        try await Task.sleep(for: .milliseconds(700))
        log("LIVE: after volDown volume=\(volume.map { "\($0.0)/\($0.1)" } ?? "unknown")")
    }
}
