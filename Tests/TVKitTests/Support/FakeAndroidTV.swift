import Foundation
import Network
import Security
@testable import TVKit

/// A fake Google TV on localhost speaking Remote v2 over TLS: a pairing port and a remote port.
final class FakeAndroidTV: @unchecked Sendable {
    // Behaviour switches
    var rejectPairingSteps = false
    var rejectSecret = false
    var skipHandshake = false   // never send set_active, so connect() times out

    private let queue = DispatchQueue(label: "fake-tv")
    private let lock = NSLock()
    private var pairListener: NWListener!
    private var remoteListener: NWListener!
    private var connections: [NWConnection] = []
    private var received: [PBFields] = []
    private var pairingReceived: [PBFields] = []

    private(set) var pairingPort: UInt16 = 0
    private(set) var remotePort: UInt16 = 0

    var messages: [PBFields] { lock.withLock { received } }
    var pairingMessages: [PBFields] { lock.withLock { pairingReceived } }

    init(identity: SecIdentity) throws {
        pairListener = try NWListener(using: Self.tls(identity), on: .any)
        remoteListener = try NWListener(using: Self.tls(identity), on: .any)
    }

    func start() async throws {
        pairListener.newConnectionHandler = { [weak self] c in self?.accept(c, pairing: true) }
        remoteListener.newConnectionHandler = { [weak self] c in self?.accept(c, pairing: false) }
        pairListener.start(queue: queue)
        remoteListener.start(queue: queue)
        guard await eventually(.seconds(5), { (self.pairListener.port?.rawValue ?? 0) > 0 && (self.remoteListener.port?.rawValue ?? 0) > 0 }) else {
            throw TVError.timeout
        }
        pairingPort = pairListener.port!.rawValue
        remotePort = remoteListener.port!.rawValue
    }

    func stop() {
        pairListener.cancel(); remoteListener.cancel()
        dropClients()
    }

    /// Closes every open client connection (the TV going away).
    func dropClients() { lock.withLock { connections.forEach { $0.cancel() }; connections = [] } }

    /// Pushes a message to every connected remote client.
    func push(_ payload: Data) {
        let framed = PB.varint(UInt64(payload.count)) + payload
        lock.withLock { connections }.forEach { $0.send(content: framed, completion: .idempotent) }
    }

    // MARK: internals

    private static func tls(_ identity: SecIdentity) -> NWParameters {
        let tls = NWProtocolTLS.Options()
        let sec = tls.securityProtocolOptions
        sec_protocol_options_set_local_identity(sec, sec_identity_create(identity)!)
        sec_protocol_options_set_peer_authentication_required(sec, true)
        sec_protocol_options_set_verify_block(sec, { _, _, complete in complete(true) }, DispatchQueue(label: "fake-tv-verify"))
        return NWParameters(tls: tls)
    }

    private func accept(_ c: NWConnection, pairing: Bool) {
        lock.withLock { connections.append(c) }
        c.stateUpdateHandler = { [weak self] state in
            guard case .ready = state, let self else { return }
            if !pairing, !self.skipHandshake {
                // A real TV opens with configure, then set_active.
                self.send(c, PB.build { $0.msg(1) { $0.int(1, 622) } })
                self.send(c, PB.build { $0.msg(2) { $0.int(1, 622) } })
            }
            self.readLoop(c, buffer: Data(), pairing: pairing)
        }
        c.start(queue: queue)
    }

    private func send(_ c: NWConnection, _ payload: Data) {
        c.send(content: PB.varint(UInt64(payload.count)) + payload, completion: .idempotent)
    }

    private func readLoop(_ c: NWConnection, buffer: Data, pairing: Bool) {
        c.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, done, error in
            guard let self else { return }
            var buf = buffer + (data ?? Data())
            while true {
                let b = [UInt8](buf)
                var i = 0
                guard let n = readVarint(b, &i), i + Int(n) <= b.count else { break }
                let msg = pbDecode(Data(b[i..<i + Int(n)]))
                buf = Data(b[(i + Int(n))...])
                self.handle(msg, on: c, pairing: pairing)
            }
            if error == nil && !done { self.readLoop(c, buffer: buf, pairing: pairing) }
        }
    }

    private func handle(_ m: PBFields, on c: NWConnection, pairing: Bool) {
        if pairing {
            lock.withLock { pairingReceived.append(m) }
            let isSecret = m[40] != nil
            let ok = isSecret ? !rejectSecret : !rejectPairingSteps
            send(c, PB.build { $0.int(1, 2); $0.int(2, ok ? 200 : 402) })
        } else {
            lock.withLock { received.append(m) }
        }
    }
}
