import Foundation

/// Compares the running version with the latest GitHub release.
public enum UpdateCheck {
    public static let repo = "ihusnainalii/tcl-tv-remote"

    public enum Result: Equatable { case available(String, URL), upToDate, failed(String) }

    public static func run(current: String) async -> Result {
        let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
        guard let (data, resp) = try? await URLSession.shared.data(from: url) else { return .failed("Couldn't reach GitHub") }
        guard (resp as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String,
              let page = (json["html_url"] as? String).flatMap(URL.init(string:)) else { return .failed("No releases published yet") }
        return isNewer(tag, than: current) ? .available(tag.trimmingCharacters(in: ["v"]), page) : .upToDate
    }

    public static func isNewer(_ tag: String, than current: String) -> Bool {
        let t = tag.trimmingCharacters(in: ["v"]), c = current.trimmingCharacters(in: ["v"])
        return t.compare(c, options: .numeric) == .orderedDescending
    }
}
