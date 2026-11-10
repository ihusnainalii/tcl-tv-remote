import Foundation
import Network
import OSLog
import TVKit

/// Turns any error into one short sentence that says what happened and what to do next.
/// The raw error goes to the system log (Console app, subsystem "app.tclremote") for debugging.
enum UserFacingError {
    private static let log = Logger(subsystem: "app.tclremote", category: "errors")

    static func message(for error: Error) -> String {
        log.error("\(String(describing: error), privacy: .public)")
        switch error {
        case let e as TVError: return message(e)
        case let e as NWError: return message(e)
        case let e as URLError: return message(e)
        default:
            let ns = error as NSError
            return ns.domain == NSPOSIXErrorDomain ? posix(Int32(ns.code)) : L10n.Error.generic
        }
    }

    static func message(_ e: TVError) -> String {
        switch e {
        case .timeout: L10n.Error.notResponding
        case .closed: L10n.Error.connectionLost
        case .rejected: L10n.Error.refused
        case .badCode: L10n.Error.badCode
        case .identity: L10n.Error.certificate
        case .unsupported(let key): L10n.Toast.unsupported(key)
        }
    }

    static func message(_ e: NWError) -> String {
        switch e {
        case .posix(let code): posix(code.rawValue)
        case .tls: L10n.Error.secureConnection
        case .dns(let code): code == -65570 ? L10n.Error.localNetwork : L10n.Error.unreachable // kDNSServiceErr_PolicyDenied
        default: L10n.Error.unreachable
        }
    }

    static func message(_ e: URLError) -> String {
        switch e.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed: L10n.Error.noWifi
        case .timedOut, .cannotConnectToHost, .cannotFindHost: L10n.Error.unreachable
        default: L10n.Error.generic
        }
    }

    static func posix(_ code: Int32) -> String {
        switch code {
        case ECONNREFUSED: L10n.Error.connectionRefused
        case ENETDOWN: L10n.Error.noWifi
        case EPERM, EACCES: L10n.Error.localNetwork
        default: L10n.Error.unreachable // EHOSTUNREACH, ENETUNREACH, ETIMEDOUT, EHOSTDOWN, ...
        }
    }
}
