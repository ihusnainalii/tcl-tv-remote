// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum About {
    /// Check for Updates
    internal static let checkForUpdates = L10n.tr("Localizable", "about.checkForUpdates", fallback: "Check for Updates")
    /// Checking…
    internal static let checking = L10n.tr("Localizable", "about.checking", fallback: "Checking…")
    /// Controls TCL Google TV, Android TV and Roku TV over your Wi-Fi. No account, no cloud.
    internal static let description = L10n.tr("Localizable", "about.description", fallback: "Controls TCL Google TV, Android TV and Roku TV over your Wi-Fi. No account, no cloud.")
    /// Download
    internal static let download = L10n.tr("Localizable", "about.download", fallback: "Download")
    /// Version %@ is available
    internal static func updateAvailable(_ p1: Any) -> String {
      return L10n.tr("Localizable", "about.updateAvailable", String(describing: p1), fallback: "Version %@ is available")
    }
    /// You're up to date
    internal static let upToDate = L10n.tr("Localizable", "about.upToDate", fallback: "You're up to date")
    /// About
    internal static func version(_ p1: Any) -> String {
      return L10n.tr("Localizable", "about.version", String(describing: p1), fallback: "Version %@")
    }
  }
  internal enum App {
    /// App
    internal static let name = L10n.tr("Localizable", "app.name", fallback: "TCL Remote")
  }
  internal enum Appearance {
    /// Dark
    internal static let dark = L10n.tr("Localizable", "appearance.dark", fallback: "Dark")
    /// Light
    internal static let light = L10n.tr("Localizable", "appearance.light", fallback: "Light")
    /// System
    internal static let system = L10n.tr("Localizable", "appearance.system", fallback: "System")
  }
  internal enum Apps {
    /// Add an app
    internal static let addAnApp = L10n.tr("Localizable", "apps.addAnApp", fallback: "Add an app")
    /// Connect to see apps
    internal static let connectToSee = L10n.tr("Localizable", "apps.connectToSee", fallback: "Connect to see apps")
    /// Open %@
    internal static func `open`(_ p1: Any) -> String {
      return L10n.tr("Localizable", "apps.open", String(describing: p1), fallback: "Open %@")
    }
    /// Remove Shortcut
    internal static let removeShortcut = L10n.tr("Localizable", "apps.removeShortcut", fallback: "Remove Shortcut")
    /// Apps
    internal static let search = L10n.tr("Localizable", "apps.search", fallback: "Search apps")
    internal enum Picker {
      /// Add %@
      internal static func addApp(_ p1: Any) -> String {
        return L10n.tr("Localizable", "apps.picker.addApp", String(describing: p1), fallback: "Add %@")
      }
      /// All of these apps are already added.
      internal static let allAdded = L10n.tr("Localizable", "apps.picker.allAdded", fallback: "All of these apps are already added.")
      /// Custom link
      internal static let customLink = L10n.tr("Localizable", "apps.picker.customLink", fallback: "Custom link")
      /// Google TV doesn't share its installed apps, so pick the ones you have. Apps that aren't installed won't open.
      internal static let explanation = L10n.tr("Localizable", "apps.picker.explanation", fallback: "Google TV doesn't share its installed apps, so pick the ones you have. Apps that aren't installed won't open.")
      /// App link, e.g. https://www.twitch.tv
      internal static let linkPlaceholder = L10n.tr("Localizable", "apps.picker.linkPlaceholder", fallback: "App link, e.g. https://www.twitch.tv")
      /// No match. Add it with a custom link below.
      internal static let noMatch = L10n.tr("Localizable", "apps.picker.noMatch", fallback: "No match. Add it with a custom link below.")
      /// Add apps
      internal static let title = L10n.tr("Localizable", "apps.picker.title", fallback: "Add apps")
    }
  }
  internal enum Common {
    /// Add
    internal static let add = L10n.tr("Localizable", "common.add", fallback: "Add")
    /// Add to Favorites
    internal static let addToFavorites = L10n.tr("Localizable", "common.addToFavorites", fallback: "Add to Favorites")
    /// Shared
    internal static let cancel = L10n.tr("Localizable", "common.cancel", fallback: "Cancel")
    /// Favorite
    internal static let favorite = L10n.tr("Localizable", "common.favorite", fallback: "Favorite")
    /// Name
    internal static let name = L10n.tr("Localizable", "common.name", fallback: "Name")
    /// Remove from Favorites
    internal static let removeFromFavorites = L10n.tr("Localizable", "common.removeFromFavorites", fallback: "Remove from Favorites")
  }
  internal enum Devices {
    /// Add by IP
    internal static let addByIP = L10n.tr("Localizable", "devices.addByIP", fallback: "Add by IP")
    /// Connect
    internal static let connect = L10n.tr("Localizable", "devices.connect", fallback: "Connect")
    /// Forget
    internal static let forget = L10n.tr("Localizable", "devices.forget", fallback: "Forget")
    /// Hide
    internal static let hide = L10n.tr("Localizable", "devices.hide", fallback: "Hide")
    /// TV IP address, e.g. 192.168.1.20
    internal static let ipPlaceholder = L10n.tr("Localizable", "devices.ipPlaceholder", fallback: "TV IP address, e.g. 192.168.1.20")
    /// Last used
    internal static let lastUsed = L10n.tr("Localizable", "devices.lastUsed", fallback: "Last used")
    /// TCL TV (%@)
    internal static func manualName(_ p1: Any) -> String {
      return L10n.tr("Localizable", "devices.manualName", String(describing: p1), fallback: "TCL TV (%@)")
    }
    /// No TVs found
    internal static let noTVs = L10n.tr("Localizable", "devices.noTVs", fallback: "No TVs found")
    /// On this network
    internal static let onThisNetwork = L10n.tr("Localizable", "devices.onThisNetwork", fallback: "On this network")
    /// Devices screen
    internal static let recent = L10n.tr("Localizable", "devices.recent", fallback: "Recent")
    /// Rename…
    internal static let rename = L10n.tr("Localizable", "devices.rename", fallback: "Rename…")
    /// Rename TV
    internal static let renameTitle = L10n.tr("Localizable", "devices.renameTitle", fallback: "Rename TV")
    /// Make sure your Mac and TV are on the same Wi-Fi.
    internal static let sameWifi = L10n.tr("Localizable", "devices.sameWifi", fallback: "Make sure your Mac and TV are on the same Wi-Fi.")
    /// Save
    internal static let save = L10n.tr("Localizable", "devices.save", fallback: "Save")
    /// Scan
    internal static let scan = L10n.tr("Localizable", "devices.scan", fallback: "Scan")
    /// Scanning…
    internal static let scanning = L10n.tr("Localizable", "devices.scanning", fallback: "Scanning…")
    /// Scanning for TVs
    internal static let scanningForTVs = L10n.tr("Localizable", "devices.scanningForTVs", fallback: "Scanning for TVs")
  }
  internal enum Header {
    /// Header and ⋯ menu
    internal static let closeSettings = L10n.tr("Localizable", "header.closeSettings", fallback: "Close Settings")
    /// More options
    internal static let moreOptions = L10n.tr("Localizable", "header.moreOptions", fallback: "More options")
    /// Remote
    internal static let remote = L10n.tr("Localizable", "header.remote", fallback: "Remote")
    /// TVs
    internal static let tvs = L10n.tr("Localizable", "header.tvs", fallback: "TVs")
  }
  internal enum Menu {
    /// Find TVs…
    internal static let findTVs = L10n.tr("Localizable", "menu.findTVs", fallback: "Find TVs…")
    /// Launch at Login
    internal static let launchAtLogin = L10n.tr("Localizable", "menu.launchAtLogin", fallback: "Launch at Login")
    /// Quit TCL Remote
    internal static let quit = L10n.tr("Localizable", "menu.quit", fallback: "Quit TCL Remote")
    /// Settings…
    internal static let settings = L10n.tr("Localizable", "menu.settings", fallback: "Settings…")
  }
  internal enum Notification {
    internal enum Disconnected {
      /// %@ dropped the connection. Retrying…
      internal static func body(_ p1: Any) -> String {
        return L10n.tr("Localizable", "notification.disconnected.body", String(describing: p1), fallback: "%@ dropped the connection. Retrying…")
      }
      /// macOS notifications
      internal static let title = L10n.tr("Localizable", "notification.disconnected.title", fallback: "TV disconnected")
    }
    internal enum Paired {
      /// %@ is ready to control.
      internal static func body(_ p1: Any) -> String {
        return L10n.tr("Localizable", "notification.paired.body", String(describing: p1), fallback: "%@ is ready to control.")
      }
      /// Paired
      internal static let title = L10n.tr("Localizable", "notification.paired.title", fallback: "Paired")
    }
    internal enum PairingRequired {
      /// Pairing required
      internal static let title = L10n.tr("Localizable", "notification.pairingRequired.title", fallback: "Pairing required")
    }
    internal enum Reconnected {
      /// %@ is back.
      internal static func body(_ p1: Any) -> String {
        return L10n.tr("Localizable", "notification.reconnected.body", String(describing: p1), fallback: "%@ is back.")
      }
      /// Reconnected
      internal static let title = L10n.tr("Localizable", "notification.reconnected.title", fallback: "Reconnected")
    }
    internal enum Unavailable {
      /// TV unavailable
      internal static let title = L10n.tr("Localizable", "notification.unavailable.title", fallback: "TV unavailable")
    }
  }
  internal enum Pairing {
    /// Pair
    internal static let pair = L10n.tr("Localizable", "pairing.pair", fallback: "Pair")
    /// A 6-character code is showing on screen.
    internal static let subtitle = L10n.tr("Localizable", "pairing.subtitle", fallback: "A 6-character code is showing on screen.")
    /// Pairing screen
    internal static let title = L10n.tr("Localizable", "pairing.title", fallback: "Enter the code on your TV")
  }
  internal enum Remote {
    /// AV
    internal static let av = L10n.tr("Localizable", "remote.av", fallback: "AV")
    /// CH
    internal static let channelShort = L10n.tr("Localizable", "remote.channelShort", fallback: "CH")
    /// HDMI %@
    internal static func hdmi(_ p1: Any) -> String {
      return L10n.tr("Localizable", "remote.hdmi", String(describing: p1), fallback: "HDMI %@")
    }
    /// Input
    internal static let input = L10n.tr("Localizable", "remote.input", fallback: "Input")
    /// Input source
    internal static let inputSource = L10n.tr("Localizable", "remote.inputSource", fallback: "Input source")
    /// Live TV
    internal static let liveTV = L10n.tr("Localizable", "remote.liveTV", fallback: "Live TV")
    /// Remote screen
    internal static let power = L10n.tr("Localizable", "remote.power", fallback: "Power")
    /// Re-pair
    internal static let repair = L10n.tr("Localizable", "remote.repair", fallback: "Re-pair")
    /// Retry
    internal static let retry = L10n.tr("Localizable", "remote.retry", fallback: "Retry")
    /// VOL
    internal static let volumeShort = L10n.tr("Localizable", "remote.volumeShort", fallback: "VOL")
    internal enum OfflineCard {
      /// Retrying automatically…
      internal static let subtitle = L10n.tr("Localizable", "remote.offlineCard.subtitle", fallback: "Retrying automatically…")
      /// TV is unreachable
      internal static let title = L10n.tr("Localizable", "remote.offlineCard.title", fallback: "TV is unreachable")
    }
    internal enum PairCard {
      /// One-time setup. A code will appear on the TV.
      internal static let subtitle = L10n.tr("Localizable", "remote.pairCard.subtitle", fallback: "One-time setup. A code will appear on the TV.")
      /// Pair with this TV
      internal static let title = L10n.tr("Localizable", "remote.pairCard.title", fallback: "Pair with this TV")
    }
    internal enum Tab {
      /// Apps
      internal static let apps = L10n.tr("Localizable", "remote.tab.apps", fallback: "Apps")
      /// Keypad
      internal static let keypad = L10n.tr("Localizable", "remote.tab.keypad", fallback: "Keypad")
      /// More
      internal static let more = L10n.tr("Localizable", "remote.tab.more", fallback: "More")
      /// Type
      internal static let type = L10n.tr("Localizable", "remote.tab.type", fallback: "Type")
    }
    internal enum Typing {
      /// Enter
      internal static let enter = L10n.tr("Localizable", "remote.typing.enter", fallback: "Enter")
      /// Send Enter to the TV
      internal static let enterHelp = L10n.tr("Localizable", "remote.typing.enterHelp", fallback: "Send Enter to the TV")
      /// Open a search or text box on the TV, then type here. Letters appear on the TV as you type; Return sends Enter.
      internal static let hint = L10n.tr("Localizable", "remote.typing.hint", fallback: "Open a search or text box on the TV, then type here. Letters appear on the TV as you type; Return sends Enter.")
      /// Type on TV…
      internal static let placeholder = L10n.tr("Localizable", "remote.typing.placeholder", fallback: "Type on TV…")
    }
  }
  internal enum Settings {
    /// Appearance
    internal static let appearance = L10n.tr("Localizable", "settings.appearance", fallback: "Appearance")
    /// Clear History
    internal static let clearHistory = L10n.tr("Localizable", "settings.clearHistory", fallback: "Clear History")
    /// Color theme
    internal static let colorTheme = L10n.tr("Localizable", "settings.colorTheme", fallback: "Color theme")
    /// Forget all TVs except the current one?
    internal static let confirmClear = L10n.tr("Localizable", "settings.confirmClear", fallback: "Forget all TVs except the current one?")
    /// Reset Google TV pairing?
    internal static let confirmReset = L10n.tr("Localizable", "settings.confirmReset", fallback: "Reset Google TV pairing?")
    /// Connect automatically
    internal static let connectAutomatically = L10n.tr("Localizable", "settings.connectAutomatically", fallback: "Connect automatically")
    /// Connection
    internal static let connection = L10n.tr("Localizable", "settings.connection", fallback: "Connection")
    /// Custom color
    internal static let customColor = L10n.tr("Localizable", "settings.customColor", fallback: "Custom color")
    /// Favorite: connects first
    internal static let favoriteHelp = L10n.tr("Localizable", "settings.favoriteHelp", fallback: "Favorite: connects first")
    /// Forget this TV
    internal static let forgetHelp = L10n.tr("Localizable", "settings.forgetHelp", fallback: "Forget this TV")
    /// Keyboard
    internal static let keyboard = L10n.tr("Localizable", "settings.keyboard", fallback: "Keyboard")
    /// Launch at login
    internal static let launchAtLogin = L10n.tr("Localizable", "settings.launchAtLogin", fallback: "Launch at login")
    /// Notifications
    internal static let notifications = L10n.tr("Localizable", "settings.notifications", fallback: "Notifications")
    /// Deletes the pairing certificate from your Keychain. Every Google TV will show a new code to pair again.
    internal static let resetMessage = L10n.tr("Localizable", "settings.resetMessage", fallback: "Deletes the pairing certificate from your Keychain. Every Google TV will show a new code to pair again.")
    /// Reset Pairing
    internal static let resetPairing = L10n.tr("Localizable", "settings.resetPairing", fallback: "Reset Pairing")
    /// Retry offline TV every
    internal static let retryEvery = L10n.tr("Localizable", "settings.retryEvery", fallback: "Retry offline TV every")
    /// Saved TVs
    internal static let savedTVs = L10n.tr("Localizable", "settings.savedTVs", fallback: "Saved TVs")
    /// Startup
    internal static let startup = L10n.tr("Localizable", "settings.startup", fallback: "Startup")
    internal enum Keyboard {
      /// Backspace
      internal static let backspace = L10n.tr("Localizable", "settings.keyboard.backspace", fallback: "Backspace")
      /// Navigate
      internal static let navigate = L10n.tr("Localizable", "settings.keyboard.navigate", fallback: "Navigate")
      /// OK · Back
      internal static let okBack = L10n.tr("Localizable", "settings.keyboard.okBack", fallback: "OK · Back")
      /// Play · Mute · Home
      internal static let playMuteHome = L10n.tr("Localizable", "settings.keyboard.playMuteHome", fallback: "Play · Mute · Home")
      /// Volume
      internal static let volume = L10n.tr("Localizable", "settings.keyboard.volume", fallback: "Volume")
    }
    internal enum SavedTVs {
      /// TVs appear here after you connect to them.
      internal static let empty = L10n.tr("Localizable", "settings.savedTVs.empty", fallback: "TVs appear here after you connect to them.")
    }
    internal enum Tab {
      /// About
      internal static let about = L10n.tr("Localizable", "settings.tab.about", fallback: "About")
      /// Settings
      internal static let general = L10n.tr("Localizable", "settings.tab.general", fallback: "General")
      /// Look
      internal static let look = L10n.tr("Localizable", "settings.tab.look", fallback: "Look")
      /// TVs
      internal static let tvs = L10n.tr("Localizable", "settings.tab.tvs", fallback: "TVs")
    }
  }
  internal enum Status {
    /// Connected
    internal static let connected = L10n.tr("Localizable", "status.connected", fallback: "Connected")
    /// Connecting…
    internal static let connecting = L10n.tr("Localizable", "status.connecting", fallback: "Connecting…")
    /// Connection status (header)
    internal static let notConnected = L10n.tr("Localizable", "status.notConnected", fallback: "Not connected")
    /// Offline
    internal static let offline = L10n.tr("Localizable", "status.offline", fallback: "Offline")
    /// Pairing required
    internal static let pairingRequired = L10n.tr("Localizable", "status.pairingRequired", fallback: "Pairing required")
    /// Standby
    internal static let standby = L10n.tr("Localizable", "status.standby", fallback: "Standby")
  }
  internal enum Theme {
    /// Custom
    internal static let custom = L10n.tr("Localizable", "theme.custom", fallback: "Custom")
    /// Forest
    internal static let forest = L10n.tr("Localizable", "theme.forest", fallback: "Forest")
    /// Graphite
    internal static let graphite = L10n.tr("Localizable", "theme.graphite", fallback: "Graphite")
    /// Ocean
    internal static let ocean = L10n.tr("Localizable", "theme.ocean", fallback: "Ocean")
    /// Rose
    internal static let rose = L10n.tr("Localizable", "theme.rose", fallback: "Rose")
    /// Sunset
    internal static let sunset = L10n.tr("Localizable", "theme.sunset", fallback: "Sunset")
    /// TCL Red
    internal static let tclRed = L10n.tr("Localizable", "theme.tclRed", fallback: "TCL Red")
    /// Themes and appearance
    internal static let violet = L10n.tr("Localizable", "theme.violet", fallback: "Violet")
  }
  internal enum Toast {
    /// Couldn't change login item: %@
    internal static func loginItemFailed(_ p1: Any) -> String {
      return L10n.tr("Localizable", "toast.loginItemFailed", String(describing: p1), fallback: "Couldn't change login item: %@")
    }
    /// Opening %@…
    internal static func opening(_ p1: Any) -> String {
      return L10n.tr("Localizable", "toast.opening", String(describing: p1), fallback: "Opening %@…")
    }
    /// Paired
    internal static let paired = L10n.tr("Localizable", "toast.paired", fallback: "Paired")
    /// Pairing failed: %@
    internal static func pairingFailed(_ p1: Any) -> String {
      return L10n.tr("Localizable", "toast.pairingFailed", String(describing: p1), fallback: "Pairing failed: %@")
    }
    /// Pairing reset. Google TVs will ask for a new code.
    internal static let pairingReset = L10n.tr("Localizable", "toast.pairingReset", fallback: "Pairing reset. Google TVs will ask for a new code.")
    /// Toasts
    internal static let reconnected = L10n.tr("Localizable", "toast.reconnected", fallback: "Reconnected")
    /// %@ isn't available on this TV
    internal static func unsupported(_ p1: Any) -> String {
      return L10n.tr("Localizable", "toast.unsupported", String(describing: p1), fallback: "%@ isn't available on this TV")
    }
  }
  internal enum Volume {
    /// Volume
    internal static let label = L10n.tr("Localizable", "volume.label", fallback: "Volume")
    /// Volume bar
    internal static let mute = L10n.tr("Localizable", "volume.mute", fallback: "Mute")
    /// Muted
    internal static let muted = L10n.tr("Localizable", "volume.muted", fallback: "Muted")
    /// Unmute
    internal static let unmute = L10n.tr("Localizable", "volume.unmute", fallback: "Unmute")
    /// %d of %d
    internal static func value(_ p1: Int, _ p2: Int) -> String {
      return L10n.tr("Localizable", "volume.value", p1, p2, fallback: "%d of %d")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
