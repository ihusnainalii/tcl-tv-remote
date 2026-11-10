import Foundation

/// The single place that maps a TV platform to its protocol driver.
public enum RemoteFactory {
    @MainActor
    public static func make(for tv: TV) -> TVRemote {
        switch tv.kind {
        case .roku: RokuRemote(host: tv.host)
        case .androidTV: AndroidTVRemote(host: tv.host)
        }
    }
}
