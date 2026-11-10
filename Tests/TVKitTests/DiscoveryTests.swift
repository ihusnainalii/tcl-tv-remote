import Darwin
import Network
import XCTest
@testable import TVKit

/// Discovery against a local SSDP responder and a test-only Bonjour service.
@MainActor
final class DiscoveryTests: XCTestCase {
    override func setUp() { StubURLProtocol.install() }
    override func tearDown() { StubURLProtocol.uninstall() }

    func testFindsRokuAndGoogleTV() async throws {
        StubURLProtocol.on("/query/device-info", "<device-info><user-device-name>Den Roku</user-device-name></device-info>")
        let responder = try SSDPResponder()
        let bonjour = try NWListener(using: .tcp)
        bonjour.service = NWListener.Service(name: "Test Google TV", type: "_tclremotetest._tcp")
        bonjour.newConnectionHandler = { c in c.start(queue: .main); c.cancel() }
        bonjour.start(queue: .main)
        defer { bonjour.cancel(); responder.stop() }

        var found: [TV] = []
        let discovery = Discovery(serviceType: "_tclremotetest._tcp", ssdpHost: "127.0.0.1", ssdpPort: responder.port,
                                  ssdpSeconds: 2, settle: .seconds(2))
        await discovery.scan { found.append($0) }

        XCTAssertTrue(found.contains { $0.kind == .roku && $0.host == "127.0.0.1" && $0.name == "Den Roku" }, "\(found)")
        XCTAssertTrue(found.contains { $0.kind == .androidTV && $0.name == "Test Google TV" }, "\(found)")
        XCTAssertTrue(responder.sawSearch, "M-SEARCH for roku:ecp was sent")
    }

    func testSSDPWithNoAnswers() {
        let hosts = Discovery.ssdp(searchTarget: "roku:ecp", host: "127.0.0.1", port: 9, seconds: 1)
        XCTAssertEqual(hosts, [])
    }
}

/// Answers one SSDP M-SEARCH on localhost like a Roku would.
final class SSDPResponder: @unchecked Sendable {
    let fd: Int32
    let port: UInt16
    private(set) var sawSearch = false
    private var running = true

    init() throws {
        let sock = socket(AF_INET, SOCK_DGRAM, 0)
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = 0
        inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr)
        let bound = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
        }
        guard bound == 0 else { throw TVError.closed }
        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        _ = withUnsafeMutablePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(sock, $0, &len) }
        }
        let boundPort = UInt16(bigEndian: addr.sin_port)
        var tv = timeval(tv_sec: 0, tv_usec: 200_000)
        setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
        fd = sock
        port = boundPort
        Thread.detachNewThread { [self] in serve() }
    }

    private func serve() {
        var buf = [UInt8](repeating: 0, count: 2048)
        while running {
            var from = sockaddr_storage()
            var len = socklen_t(MemoryLayout<sockaddr_storage>.size)
            let n = withUnsafeMutablePointer(to: &from) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { recvfrom(fd, &buf, buf.count, 0, $0, &len) }
            }
            guard n > 0, String(bytes: buf[0..<n], encoding: .utf8)?.contains("ST: roku:ecp") == true else { continue }
            sawSearch = true
            let reply = "HTTP/1.1 200 OK\r\nST: roku:ecp\r\nLOCATION: http://127.0.0.1:8060/\r\n\r\n"
            _ = reply.withCString { p in
                withUnsafePointer(to: &from) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { sendto(fd, p, strlen(p), 0, $0, len) }
                }
            }
        }
    }

    func stop() { running = false; close(fd) }
}
