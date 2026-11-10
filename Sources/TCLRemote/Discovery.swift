import Darwin
import Foundation
import Network

/// Finds Google/Android TVs via Bonjour and Roku TVs via SSDP.
@MainActor
final class Discovery {
    private var browser: NWBrowser?
    private var resolving: [NWConnection] = []

    func scan(found: @escaping @MainActor (TV) -> Void) async {
        let b = NWBrowser(for: .bonjour(type: "_androidtvremote2._tcp", domain: nil), using: .tcp)
        b.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor in results.forEach { self?.resolve($0, found: found) } }
        }
        b.start(queue: .main)
        browser = b

        let rokus = await Task.detached { Self.ssdp(searchTarget: "roku:ecp", seconds: 4) }.value
        await withTaskGroup(of: TV?.self) { group in
            for host in rokus {
                group.addTask { TV(name: await RokuRemote.name(host: host) ?? "Roku TV \(host)", host: host, kind: .roku) }
            }
            for await tv in group { if let tv { found(tv) } }
        }
        try? await Task.sleep(for: .seconds(1)) // give Bonjour stragglers a moment
        b.cancel(); browser = nil
        resolving.forEach { $0.cancel() }; resolving = []
    }

    /// Bonjour gives a service name; open a throwaway TCP connection to learn its IPv4 address.
    private func resolve(_ result: NWBrowser.Result, found: @escaping @MainActor (TV) -> Void) {
        guard case let .service(name, _, _, _) = result.endpoint else { return }
        let params = NWParameters.tcp
        (params.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options)?.version = .v4
        let c = NWConnection(to: result.endpoint, using: params)
        c.stateUpdateHandler = { state in
            switch state {
            case .ready:
                if case let .hostPort(host, _)? = c.currentPath?.remoteEndpoint {
                    let ip = "\(host)".components(separatedBy: "%")[0]
                    Task { @MainActor in found(TV(name: name, host: ip, kind: .androidTV)) }
                }
                c.cancel()
            case .failed: c.cancel()
            default: break
            }
        }
        resolving.append(c)
        c.start(queue: .main)
    }

    /// SSDP M-SEARCH over plain BSD sockets; returns hosts from LOCATION headers.
    nonisolated static func ssdp(searchTarget: String, seconds: Int) -> [String] {
        let fd = socket(AF_INET, SOCK_DGRAM, 0)
        guard fd >= 0 else { return [] }
        defer { close(fd) }
        var tv = timeval(tv_sec: 0, tv_usec: 500_000)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = UInt16(1900).bigEndian
        inet_pton(AF_INET, "239.255.255.250", &addr.sin_addr)
        let msg = "M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nST: \(searchTarget)\r\nMX: 2\r\n\r\n"
        for _ in 0..<2 { // UDP: send twice
            _ = msg.withCString { p in
                withUnsafePointer(to: &addr) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        sendto(fd, p, strlen(p), 0, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                    }
                }
            }
        }

        var hosts = Set<String>()
        let deadline = Date().addingTimeInterval(TimeInterval(seconds))
        var buf = [UInt8](repeating: 0, count: 2048)
        while Date() < deadline {
            let n = recv(fd, &buf, buf.count, 0)
            guard n > 0, let text = String(bytes: buf[0..<n], encoding: .utf8) else { continue }
            if let m = text.firstMatch(of: try! Regex(#"(?i)location:\s*https?://([^:/\s]+)"#)), let h = m[1].substring {
                hosts.insert(String(h))
            }
        }
        return Array(hosts)
    }
}
