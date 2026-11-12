import AppIntents
import TVKit

// Siri, Shortcuts, Spotlight and the Action Button. Each action talks to the most recently used TV
// directly, in the background, without opening the app.

/// Remote buttons offered to Siri and Shortcuts.
enum TVButton: String, AppEnum {
    case power, home, back, ok, up, down, left, right, mute, volumeUp, volumeDown
    case channelUp, channelDown, playPause, rewind, forward, settings, search

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "TV Button"
    static let caseDisplayRepresentations: [TVButton: DisplayRepresentation] = [
        .power: "Power", .home: "Home", .back: "Back", .ok: "OK",
        .up: "Up", .down: "Down", .left: "Left", .right: "Right",
        .mute: "Mute", .volumeUp: "Volume Up", .volumeDown: "Volume Down",
        .channelUp: "Channel Up", .channelDown: "Channel Down", .playPause: "Play/Pause",
        .rewind: "Rewind", .forward: "Fast Forward", .settings: "Settings", .search: "Search",
    ]

    var key: Key {
        switch self {
        case .power: .power; case .home: .home; case .back: .back; case .ok: .ok
        case .up: .up; case .down: .down; case .left: .left; case .right: .right
        case .mute: .mute; case .volumeUp: .volUp; case .volumeDown: .volDown
        case .channelUp: .chUp; case .channelDown: .chDown; case .playPause: .playPause
        case .rewind: .rewind; case .forward: .forward; case .settings: .settings; case .search: .search
        }
    }
}

enum VolumeDirection: String, AppEnum {
    case up, down
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Direction"
    static let caseDisplayRepresentations: [VolumeDirection: DisplayRepresentation] = [
        .up: DisplayRepresentation(title: "Volume Up", synonyms: ["up", "louder"]),
        .down: DisplayRepresentation(title: "Volume Down", synonyms: ["down", "quieter"]),
    ]
}

struct PressButtonIntent: AppIntent {
    static let title: LocalizedStringResource = "Press TV Button"
    static let description = IntentDescription("Presses a remote button on your TV.")

    @Parameter(title: "Button") var button: TVButton
    @Parameter(title: "Times", default: 1, inclusiveRange: (1, 50)) var times: Int

    static var parameterSummary: some ParameterSummary { Summary("Press \(\.$button) \(\.$times) times") }

    init() {}
    init(button: TVButton) { self.button = button }

    func perform() async throws -> some IntentResult {
        try await TVCommand.run { remote in
            for _ in 0..<times { try await remote.press(button.key) }
        }
        return .result()
    }
}

struct PowerIntent: AppIntent {
    static let title: LocalizedStringResource = "Turn TV On or Off"
    static let description = IntentDescription("Presses the power button on your TV.")

    func perform() async throws -> some IntentResult {
        try await TVCommand.run { try await $0.press(.power) }
        return .result()
    }
}

struct ChangeVolumeIntent: AppIntent {
    static let title: LocalizedStringResource = "Change TV Volume"
    static let description = IntentDescription("Turns the TV volume up or down by a few steps.")

    @Parameter(title: "Direction", default: .up) var direction: VolumeDirection
    @Parameter(title: "Steps", default: 3, inclusiveRange: (1, 50)) var steps: Int

    static var parameterSummary: some ParameterSummary { Summary("Turn volume \(\.$direction) by \(\.$steps)") }

    func perform() async throws -> some IntentResult {
        let key: Key = direction == .up ? .volUp : .volDown
        try await TVCommand.run { remote in
            for _ in 0..<steps { try await remote.press(key) }
        }
        return .result()
    }
}

struct OpenTVAppIntent: AppIntent {
    static let title: LocalizedStringResource = "Open App on TV"
    static let description = IntentDescription("Opens an app such as YouTube or Netflix on your TV.")

    @Parameter(title: "App") var app: TVAppEntity

    static var parameterSummary: some ParameterSummary { Summary("Open \(\.$app) on the TV") }

    func perform() async throws -> some IntentResult {
        try await TVCommand.run { remote in
            // Roku apps have numeric ids, so look the app up by name on the TV itself.
            let onTV = await remote.apps().first { $0.name.localizedCaseInsensitiveCompare(app.name) == .orderedSame }
            try await remote.launch(onTV ?? TVApp(id: app.id, name: app.name))
        }
        return .result()
    }
}

/// An app Siri can open: the built-in catalog plus apps added in TCL Remote.
struct TVAppEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "TV App"
    static let defaultQuery = TVAppQuery()

    let id: String
    let name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }

    static var all: [TVAppEntity] {
        let custom = UserDefaultsTVRepository().load().flatMap { $0.customApps ?? [] }
        var seen = Set<String>()
        return (AppCatalog.googleTV + custom).filter { seen.insert($0.name.lowercased()).inserted }
            .map { TVAppEntity(id: $0.id, name: $0.name) }
    }
}

struct TVAppQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [TVAppEntity] {
        TVAppEntity.all.filter { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [TVAppEntity] {
        TVAppEntity.all.filter { $0.name.localizedCaseInsensitiveContains(string) }
    }

    func suggestedEntities() async throws -> [TVAppEntity] { TVAppEntity.all }
}

/// Connects to the TV used most recently and runs one command.
enum TVCommand {
    struct Failure: Error, CustomLocalizedStringResourceConvertible {
        let localizedStringResource: LocalizedStringResource
    }

    @MainActor
    static func run(_ command: (TVRemote) async throws -> Void) async throws {
        guard let tv = UserDefaultsTVRepository().load().max(by: { $0.lastUsed < $1.lastUsed })?.tv else {
            throw Failure(localizedStringResource: "Open TCL Remote and connect to your TV first.")
        }
        let remote = RemoteFactory.make(for: tv)
        do {
            try await remote.connect()
            try await command(remote)
        } catch {
            throw Failure(localizedStringResource: "Couldn't reach \(tv.name). Make sure it's on and on the same Wi-Fi.")
        }
    }
}

struct TCLRemoteShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: PowerIntent(), phrases: [
            "Turn off the TV with \(.applicationName)",
            "Turn on the TV with \(.applicationName)",
            "Power the TV with \(.applicationName)",
        ], shortTitle: "TV Power", systemImageName: "power")
        AppShortcut(intent: ChangeVolumeIntent(), phrases: [
            "Turn the TV \(\.$direction) with \(.applicationName)",
            "Turn \(\.$direction) the TV volume with \(.applicationName)",
        ], shortTitle: "TV Volume", systemImageName: "speaker.wave.2.fill")
        AppShortcut(intent: OpenTVAppIntent(), phrases: [
            "Open \(\.$app) on the TV with \(.applicationName)",
            "Open \(\.$app) with \(.applicationName)",
        ], shortTitle: "Open TV App", systemImageName: "square.grid.2x2.fill")
        AppShortcut(intent: PressButtonIntent(), phrases: [
            "Press \(\.$button) with \(.applicationName)",
            "\(.applicationName) \(\.$button)",
        ], shortTitle: "TV Button", systemImageName: "av.remote.fill")
    }
}
