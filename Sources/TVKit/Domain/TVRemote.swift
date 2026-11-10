import Foundation

public protocol TVRemote: AnyObject {
    func connect() async throws
    func press(_ key: Key) async throws
    func type(_ text: String) async throws
    func apps() async -> [TVApp]
    func launch(_ app: TVApp) async throws
}
