import Foundation
import Network
import Security

// MARK: - TLS connection with varint-framed messages

final class TLSConn {
    private let queue = DispatchQueue(label: "tclremote.tls")
    private var conn: NWConnection!
    private var buffer = Data()
    private(set) var serverKey: SecKey?

    init(host: String, port: UInt16, identity: SecIdentity) {
        let tls = NWProtocolTLS.Options()
        let sec = tls.securityProtocolOptions
        sec_protocol_options_set_local_identity(sec, sec_identity_create(identity)!)
        sec_protocol_options_set_verify_block(sec, { [weak self] _, trust, complete in
            let t = sec_trust_copy_ref(trust).takeRetainedValue()
            if let cert = (SecTrustCopyCertificateChain(t) as? [SecCertificate])?.first {
                self?.serverKey = SecCertificateCopyKey(cert)
            }
            complete(true) // ponytail: TVs use self-signed certs; pin on first use if MITM on LAN matters
        }, queue)
        conn = NWConnection(host: .init(host), port: .init(rawValue: port)!, using: .init(tls: tls))
    }

    func start(timeout: TimeInterval = 6) async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            var done = false
            let finish: (Result<Void, Error>) -> Void = { [conn] r in
                guard !done else { return }
                done = true
                if case .failure = r { conn?.cancel() }
                c.resume(with: r)
            }
            conn.stateUpdateHandler = { state in
                switch state {
                case .ready: finish(.success(()))
                case .failed(let e), .waiting(let e): finish(.failure(e))
                case .cancelled: finish(.failure(TVError.closed))
                default: break
                }
            }
            conn.start(queue: queue)
            queue.asyncAfter(deadline: .now() + timeout) { finish(.failure(TVError.timeout)) }
        }
    }

    func cancel() { conn.cancel() }

    func send(_ payload: Data) async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            conn.send(content: PB.varint(UInt64(payload.count)) + payload, completion: .contentProcessed { err in
                if let err { c.resume(throwing: err) } else { c.resume() }
            })
        }
    }

    func read() async throws -> PBFields {
        while true {
            let b = [UInt8](buffer)
            var i = 0
            if let n = readVarint(b, &i), i + Int(n) <= b.count {
                buffer = Data(b[(i + Int(n))...])
                return pbDecode(Data(b[i..<i + Int(n)]))
            }
            buffer += try await chunk()
        }
    }

    private func chunk() async throws -> Data {
        try await withCheckedThrowingContinuation { c in
            conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isDone, err in
                if let err {
                    c.resume(throwing: err)
                } else if let data, !data.isEmpty {
                    c.resume(returning: data)
                } else if isDone {
                    c.resume(throwing: TVError.closed)
                } else {
                    c.resume(returning: Data())
                }
            }
        }
    }
}
