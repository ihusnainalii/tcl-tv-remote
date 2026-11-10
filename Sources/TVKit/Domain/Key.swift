import Foundation

public enum Key: String, CaseIterable {
    case power, powerOn, powerOff, home, back, exit, menu, settings, info, guide, search, captions
    case up, down, left, right, ok, backspace
    case volUp, volDown, mute, chUp, chDown
    case playPause, stop, rewind, forward, previous, next
    case tuner, av, hdmi1, hdmi2, hdmi3, hdmi4
    case n0, n1, n2, n3, n4, n5, n6, n7, n8, n9

    public var digit: Int? { rawValue.first == "n" && rawValue != "next" ? Int(rawValue.dropFirst()) : nil }

    /// Roku ECP key names; empty = Roku has no such key.
    public var roku: String {
        if let d = digit { return "Lit_\(d)" }
        return switch self {
        case .power: "Power"; case .powerOn: "PowerOn"; case .powerOff: "PowerOff"
        case .home: "Home"; case .back, .exit: "Back"; case .menu, .info, .settings: "Info"
        case .search: "Search"; case .up: "Up"; case .down: "Down"; case .left: "Left"; case .right: "Right"
        case .ok: "Select"; case .backspace: "Backspace"
        case .volUp: "VolumeUp"; case .volDown: "VolumeDown"; case .mute: "VolumeMute"
        case .chUp: "ChannelUp"; case .chDown: "ChannelDown"; case .playPause: "Play"
        case .rewind: "Rev"; case .forward, .next: "Fwd"; case .previous: "InstantReplay"
        case .tuner: "InputTuner"; case .av: "InputAV1"
        case .hdmi1: "InputHDMI1"; case .hdmi2: "InputHDMI2"; case .hdmi3: "InputHDMI3"; case .hdmi4: "InputHDMI4"
        case .guide, .captions, .stop: ""
        default: ""
        }
    }

    /// Android KeyEvent codes.
    public var android: Int {
        if let d = digit { return 7 + d }
        return switch self {
        case .power: 26; case .powerOn: 224; case .powerOff: 223; case .home: 3; case .back: 4; case .exit: 111
        case .menu: 82; case .settings: 176; case .info: 165; case .guide: 172; case .search: 84; case .captions: 175
        case .up: 19; case .down: 20; case .left: 21; case .right: 22; case .ok: 23; case .backspace: 67
        case .volUp: 24; case .volDown: 25; case .mute: 164; case .chUp: 166; case .chDown: 167
        case .playPause: 85; case .stop: 86; case .rewind: 89; case .forward: 90; case .previous: 88; case .next: 87
        case .tuner: 170; case .av: 247
        case .hdmi1: 243; case .hdmi2: 244; case .hdmi3: 245; case .hdmi4: 246
        default: 0
        }
    }

    /// Human-readable name for VoiceOver and tooltips.
    public var label: String {
        if let d = digit { return "\(d)" }
        let names: [Key: String] = [.powerOn: "Power on", .powerOff: "Power off", .ok: "OK", .volUp: "Volume up",
            .volDown: "Volume down", .chUp: "Channel up", .chDown: "Channel down", .playPause: "Play/Pause",
            .tuner: "Live TV", .av: "AV", .hdmi1: "HDMI 1", .hdmi2: "HDMI 2", .hdmi3: "HDMI 3", .hdmi4: "HDMI 4"]
        return names[self] ?? rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }
}
