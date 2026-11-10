import Foundation

/// Intercepts URLSession.shared so HTTP code (Roku, App Store, GitHub) runs against canned responses.
final class StubURLProtocol: URLProtocol {
    struct Response { var status = 200; var body = Data() }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var routes: [String: Response] = [:]   // "METHOD path" or "path"
    nonisolated(unsafe) private static var log: [String] = []
    nonisolated(unsafe) static var failAll = false

    static func install() { URLProtocol.registerClass(StubURLProtocol.self); reset() }
    static func uninstall() { URLProtocol.unregisterClass(StubURLProtocol.self); reset() }

    static func reset() { lock.withLock { routes = [:]; log = []; failAll = false } }

    static func on(_ key: String, status: Int = 200, _ body: String = "") {
        lock.withLock { routes[key] = Response(status: status, body: Data(body.utf8)) }
    }

    /// Requests seen, as "METHOD path?query".
    static var requests: [String] { lock.withLock { log } }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let url = request.url!
        let method = request.httpMethod ?? "GET"
        let path = url.path + (url.query.map { "?" + $0 } ?? "")
        let (response, fail) = Self.lock.withLock { () -> (Response?, Bool) in
            Self.log.append("\(method) \(path)")
            return (Self.routes["\(method) \(url.path)"] ?? Self.routes[url.path], Self.failAll)
        }
        if fail { client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet)); return }
        let r = response ?? Response(status: 404)
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: url, statusCode: r.status, httpVersion: nil, headerFields: nil)!,
                            cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: r.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
