// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  public enum About {
    /// Check for Updates
    public static let checkForUpdates = L10n.tr("Localizable", "about.checkForUpdates", fallback: "Check for Updates")
    /// Checking…
    public static let checking = L10n.tr("Localizable", "about.checking", fallback: "Checking…")
    /// Controls TCL Google TV, Android TV and Roku TV over your Wi-Fi. No account, no cloud.
    public static let description = L10n.tr("Localizable", "about.description", fallback: "Controls TCL Google TV, Android TV and Roku TV over your Wi-Fi. No account, no cloud.")
    /// Download
    public static let download = L10n.tr("Localizable", "about.download", fallback: "Download")
    /// Version %@ is available
    public static func updateAvailable(_ p1: Any) -> String {
      return L10n.tr("Localizable", "about.updateAvailable", String(describing: p1), fallback: "Version %@ is available")
    }
    /// You're up to date
    public static let upToDate = L10n.tr("Localizable", "about.upToDate", fallback: "You're up to date")
    /// About
    public static func version(_ p1: Any) -> String {
      return L10n.tr("Localizable", "about.version", String(describing: p1), fallback: "Version %@")
    }
  }
  public enum App {
    /// App
    public static let name = L10n.tr("Localizable", "app.name", fallback: "TCL Remote")
  }
  public enum Appearance {
    /// Dark
    public static let dark = L10n.tr("Localizable", "appearance.dark", fallback: "Dark")
    /// Light
    public static let light = L10n.tr("Localizable", "appearance.light", fallback: "Light")
    /// System
    public static let system = L10n.tr("Localizable", "appearance.system", fallback: "System")
  }
  public enum Apps {
    /// Add an app
    public static let addAnApp = L10n.tr("Localizable", "apps.addAnApp", fallback: "Add an app")
    /// Connect to see apps
    public static let connectToSee = L10n.tr("Localizable", "apps.connectToSee", fallback: "Connect to see apps")
    /// Open %@
    public static func `open`(_ p1: Any) -> String {
      return L10n.tr("Localizable", "apps.open", String(describing: p1), fallback: "Open %@")
    }
    /// Remove Shortcut
    public static let removeShortcut = L10n.tr("Localizable", "apps.removeShortcut", fallback: "Remove Shortcut")
    /// Apps
    public static let search = L10n.tr("Localizable", "apps.search", fallback: "Search apps")
    public enum Picker {
      /// Add %@
      public static func addApp(_ p1: Any) -> String {
        return L10n.tr("Localizable", "apps.picker.addApp", String(describing: p1), fallback: "Add %@")
      }
      /// All of these apps are already added.
      public static let allAdded = L10n.tr("Localizable", "apps.picker.allAdded", fallback: "All of these apps are already added.")
      /// Custom link
      public static let customLink = L10n.tr("Localizable", "apps.picker.customLink", fallback: "Custom link")
      /// Google TV doesn't share its installed apps, so pick the ones you have. Apps that aren't installed won't open.
      public static let explanation = L10n.tr("Localizable", "apps.picker.explanation", fallback: "Google TV doesn't share its installed apps, so pick the ones you have. Apps that aren't installed won't open.")
      /// App link, e.g. https://www.twitch.tv
      public static let linkPlaceholder = L10n.tr("Localizable", "apps.picker.linkPlaceholder", fallback: "App link, e.g. https://www.twitch.tv")
      /// No match. Add it with a custom link below.
      public static let noMatch = L10n.tr("Localizable", "apps.picker.noMatch", fallback: "No match. Add it with a custom link below.")
      /// Add apps
      public static let title = L10n.tr("Localizable", "apps.picker.title", fallback: "Add apps")
    }
  }
  public enum Common {
    /// Add
    public static let add = L10n.tr("Localizable", "common.add", fallback: "Add")
    /// Add to Favorites
    public static let addToFavorites = L10n.tr("Localizable", "common.addToFavorites", fallback: "Add to Favorites")
    /// Shared
    public static let cancel = L10n.tr("Localizable", "common.cancel", fallback: "Cancel")
    /// Done
    public static let done = L10n.tr("Localizable", "common.done", fallback: "Done")
    /// Favorite
    public static let favorite = L10n.tr("Localizable", "common.favorite", fallback: "Favorite")
    /// Name
    public static let name = L10n.tr("Localizable", "common.name", fallback: "Name")
    /// Remove from Favorites
    public static let removeFromFavorites = L10n.tr("Localizable", "common.removeFromFavorites", fallback: "Remove from Favorites")
  }
  public enum Devices {
    /// Add by IP
    public static let addByIP = L10n.tr("Localizable", "devices.addByIP", fallback: "Add by IP")
    /// Connect
    public static let connect = L10n.tr("Localizable", "devices.connect", fallback: "Connect")
    /// Forget
    public static let forget = L10n.tr("Localizable", "devices.forget", fallback: "Forget")
    /// Hide
    public static let hide = L10n.tr("Localizable", "devices.hide", fallback: "Hide")
    /// TV IP address, e.g. 192.168.1.20
    public static let ipPlaceholder = L10n.tr("Localizable", "devices.ipPlaceholder", fallback: "TV IP address, e.g. 192.168.1.20")
    /// Last used
    public static let lastUsed = L10n.tr("Localizable", "devices.lastUsed", fallback: "Last used")
    /// TCL TV (%@)
    public static func manualName(_ p1: Any) -> String {
      return L10n.tr("Localizable", "devices.manualName", String(describing: p1), fallback: "TCL TV (%@)")
    }
    /// No TVs found
    public static let noTVs = L10n.tr("Localizable", "devices.noTVs", fallback: "No TVs found")
    /// On this network
    public static let onThisNetwork = L10n.tr("Localizable", "devices.onThisNetwork", fallback: "On this network")
    /// Devices screen
    public static let recent = L10n.tr("Localizable", "devices.recent", fallback: "Recent")
    /// Rename…
    public static let rename = L10n.tr("Localizable", "devices.rename", fallback: "Rename…")
    /// Rename TV
    public static let renameTitle = L10n.tr("Localizable", "devices.renameTitle", fallback: "Rename TV")
    /// Make sure your TV is on and connected to the same Wi-Fi.
    public static let sameWifi = L10n.tr("Localizable", "devices.sameWifi", fallback: "Make sure your TV is on and connected to the same Wi-Fi.")
    /// Save
    public static let save = L10n.tr("Localizable", "devices.save", fallback: "Save")
    /// Scan
    public static let scan = L10n.tr("Localizable", "devices.scan", fallback: "Scan")
    /// Scanning…
    public static let scanning = L10n.tr("Localizable", "devices.scanning", fallback: "Scanning…")
    /// Scanning for TVs
    public static let scanningForTVs = L10n.tr("Localizable", "devices.scanningForTVs", fallback: "Scanning for TVs")
  }
  public enum Error {
    /// That code didn't match. Check the code on the TV and try again.
    public static let badCode = L10n.tr("Localizable", "error.badCode", fallback: "That code didn't match. Check the code on the TV and try again.")
    /// Couldn't set up secure pairing. Try Settings, TVs, Reset Pairing.
    public static let certificate = L10n.tr("Localizable", "error.certificate", fallback: "Couldn't set up secure pairing. Try Settings, TVs, Reset Pairing.")
    /// Lost the connection to the TV.
    public static let connectionLost = L10n.tr("Localizable", "error.connectionLost", fallback: "Lost the connection to the TV.")
    /// The TV refused the connection. It may need pairing again.
    public static let connectionRefused = L10n.tr("Localizable", "error.connectionRefused", fallback: "The TV refused the connection. It may need pairing again.")
    /// Errors: what happened and what to do
    public static let generic = L10n.tr("Localizable", "error.generic", fallback: "Something went wrong. Please try again.")
    /// TCL Remote needs Local Network access. Turn it on in Settings, Privacy & Security, Local Network.
    public static let localNetwork = L10n.tr("Localizable", "error.localNetwork", fallback: "TCL Remote needs Local Network access. Turn it on in Settings, Privacy & Security, Local Network.")
    /// The TV didn't respond. Make sure it's on and on the same Wi-Fi.
    public static let notResponding = L10n.tr("Localizable", "error.notResponding", fallback: "The TV didn't respond. Make sure it's on and on the same Wi-Fi.")
    /// You're not connected to Wi-Fi.
    public static let noWifi = L10n.tr("Localizable", "error.noWifi", fallback: "You're not connected to Wi-Fi.")
    /// The TV declined the request.
    public static let refused = L10n.tr("Localizable", "error.refused", fallback: "The TV declined the request.")
    /// The secure connection failed. Pair this TV again.
    public static let secureConnection = L10n.tr("Localizable", "error.secureConnection", fallback: "The secure connection failed. Pair this TV again.")
    /// Can't reach the TV. Make sure it's on and on the same Wi-Fi.
    public static let unreachable = L10n.tr("Localizable", "error.unreachable", fallback: "Can't reach the TV. Make sure it's on and on the same Wi-Fi.")
  }
  public enum Header {
    /// Header and ⋯ menu
    public static let closeSettings = L10n.tr("Localizable", "header.closeSettings", fallback: "Close Settings")
    /// More options
    public static let moreOptions = L10n.tr("Localizable", "header.moreOptions", fallback: "More options")
    /// Remote
    public static let remote = L10n.tr("Localizable", "header.remote", fallback: "Remote")
    /// TVs
    public static let tvs = L10n.tr("Localizable", "header.tvs", fallback: "TVs")
  }
  public enum Menu {
    /// Find TVs…
    public static let findTVs = L10n.tr("Localizable", "menu.findTVs", fallback: "Find TVs…")
    /// Launch at Login
    public static let launchAtLogin = L10n.tr("Localizable", "menu.launchAtLogin", fallback: "Launch at Login")
    /// Quit TCL Remote
    public static let quit = L10n.tr("Localizable", "menu.quit", fallback: "Quit TCL Remote")
    /// Settings…
    public static let settings = L10n.tr("Localizable", "menu.settings", fallback: "Settings…")
  }
  public enum Mobile {
    /// Find TVs
    public static let findTVs = L10n.tr("Localizable", "mobile.findTVs", fallback: "Find TVs")
    /// TVs
    public static let tvs = L10n.tr("Localizable", "mobile.tvs", fallback: "TVs")
    public enum Mode {
      /// Buttons
      public static let buttons = L10n.tr("Localizable", "mobile.mode.buttons", fallback: "Buttons")
      /// Touchpad
      public static let touchpad = L10n.tr("Localizable", "mobile.mode.touchpad", fallback: "Touchpad")
    }
    public enum Tab {
      /// Apps
      public static let apps = L10n.tr("Localizable", "mobile.tab.apps", fallback: "Apps")
      /// Keys
      public static let keys = L10n.tr("Localizable", "mobile.tab.keys", fallback: "Keys")
      /// iPhone and iPad
      public static let remote = L10n.tr("Localizable", "mobile.tab.remote", fallback: "Remote")
      /// Settings
      public static let settings = L10n.tr("Localizable", "mobile.tab.settings", fallback: "Settings")
    }
    public enum Touchpad {
      /// Swipe to move · Tap to select
      public static let hint = L10n.tr("Localizable", "mobile.touchpad.hint", fallback: "Swipe to move · Tap to select")
    }
    public enum Welcome {
      /// Make sure this device and your TV are on the same Wi-Fi.
      public static let subtitle = L10n.tr("Localizable", "mobile.welcome.subtitle", fallback: "Make sure this device and your TV are on the same Wi-Fi.")
      /// Find your TCL TV
      public static let title = L10n.tr("Localizable", "mobile.welcome.title", fallback: "Find your TCL TV")
    }
  }
  public enum Notification {
    public enum Disconnected {
      /// %@ dropped the connection. Retrying…
      public static func body(_ p1: Any) -> String {
        return L10n.tr("Localizable", "notification.disconnected.body", String(describing: p1), fallback: "%@ dropped the connection. Retrying…")
      }
      /// macOS notifications
      public static let title = L10n.tr("Localizable", "notification.disconnected.title", fallback: "TV disconnected")
    }
    public enum Paired {
      /// %@ is ready to control.
      public static func body(_ p1: Any) -> String {
        return L10n.tr("Localizable", "notification.paired.body", String(describing: p1), fallback: "%@ is ready to control.")
      }
      /// Paired
      public static let title = L10n.tr("Localizable", "notification.paired.title", fallback: "Paired")
    }
    public enum PairingRequired {
      /// Pairing required
      public static let title = L10n.tr("Localizable", "notification.pairingRequired.title", fallback: "Pairing required")
    }
    public enum Reconnected {
      /// %@ is back.
      public static func body(_ p1: Any) -> String {
        return L10n.tr("Localizable", "notification.reconnected.body", String(describing: p1), fallback: "%@ is back.")
      }
      /// Reconnected
      public static let title = L10n.tr("Localizable", "notification.reconnected.title", fallback: "Reconnected")
    }
    public enum Unavailable {
      /// TV unavailable
      public static let title = L10n.tr("Localizable", "notification.unavailable.title", fallback: "TV unavailable")
    }
  }
  public enum Onboarding {
    /// Next
    public static let next = L10n.tr("Localizable", "onboarding.next", fallback: "Next")
    /// Show Tutorial
    public static let showAgain = L10n.tr("Localizable", "onboarding.showAgain", fallback: "Show Tutorial")
    /// Onboarding (iPhone and iPad)
    public static let skip = L10n.tr("Localizable", "onboarding.skip", fallback: "Skip")
    /// Get Started
    public static let start = L10n.tr("Localizable", "onboarding.start", fallback: "Get Started")
    public enum Apps {
      /// Open Netflix, YouTube and more in one tap, and type searches with your keyboard instead of the arrows.
      public static let body = L10n.tr("Localizable", "onboarding.apps.body", fallback: "Open Netflix, YouTube and more in one tap, and type searches with your keyboard instead of the arrows.")
      /// Apps and typing
      public static let title = L10n.tr("Localizable", "onboarding.apps.title", fallback: "Apps and typing")
    }
    public enum Control {
      /// Use the big arrow pad, or switch to the touchpad: swipe to move, tap to select. Volume, channels and media are right below.
      public static let body = L10n.tr("Localizable", "onboarding.control.body", fallback: "Use the big arrow pad, or switch to the touchpad: swipe to move, tap to select. Volume, channels and media are right below.")
      /// Buttons or touchpad
      public static let title = L10n.tr("Localizable", "onboarding.control.title", fallback: "Buttons or touchpad")
    }
    public enum Find {
      /// TCL Remote finds Google TV, Android TV and Roku TV on your Wi-Fi. No account, no cloud.
      public static let body = L10n.tr("Localizable", "onboarding.find.body", fallback: "TCL Remote finds Google TV, Android TV and Roku TV on your Wi-Fi. No account, no cloud.")
      /// Your TCL TV, in your hand
      public static let title = L10n.tr("Localizable", "onboarding.find.title", fallback: "Your TCL TV, in your hand")
    }
    public enum Pair {
      /// Google TV shows a 6-character code. Enter it once and the app reconnects by itself from then on.
      public static let body = L10n.tr("Localizable", "onboarding.pair.body", fallback: "Google TV shows a 6-character code. Enter it once and the app reconnects by itself from then on.")
      /// Pair once
      public static let title = L10n.tr("Localizable", "onboarding.pair.title", fallback: "Pair once")
    }
  }
  public enum Pairing {
    /// Pair
    public static let pair = L10n.tr("Localizable", "pairing.pair", fallback: "Pair")
    /// A 6-character code is showing on screen.
    public static let subtitle = L10n.tr("Localizable", "pairing.subtitle", fallback: "A 6-character code is showing on screen.")
    /// Pairing screen
    public static let title = L10n.tr("Localizable", "pairing.title", fallback: "Enter the code on your TV")
  }
  public enum Remote {
    /// AV
    public static let av = L10n.tr("Localizable", "remote.av", fallback: "AV")
    /// CH
    public static let channelShort = L10n.tr("Localizable", "remote.channelShort", fallback: "CH")
    /// HDMI %@
    public static func hdmi(_ p1: Any) -> String {
      return L10n.tr("Localizable", "remote.hdmi", String(describing: p1), fallback: "HDMI %@")
    }
    /// Input
    public static let input = L10n.tr("Localizable", "remote.input", fallback: "Input")
    /// Input source
    public static let inputSource = L10n.tr("Localizable", "remote.inputSource", fallback: "Input source")
    /// Live TV
    public static let liveTV = L10n.tr("Localizable", "remote.liveTV", fallback: "Live TV")
    /// Remote screen
    public static let power = L10n.tr("Localizable", "remote.power", fallback: "Power")
    /// Re-pair
    public static let repair = L10n.tr("Localizable", "remote.repair", fallback: "Re-pair")
    /// Retry
    public static let retry = L10n.tr("Localizable", "remote.retry", fallback: "Retry")
    /// VOL
    public static let volumeShort = L10n.tr("Localizable", "remote.volumeShort", fallback: "VOL")
    public enum OfflineCard {
      /// Stopped trying after 5 attempts. Tap Retry when the TV is on.
      public static let stopped = L10n.tr("Localizable", "remote.offlineCard.stopped", fallback: "Stopped trying after 5 attempts. Tap Retry when the TV is on.")
      /// Retrying automatically…
      public static let subtitle = L10n.tr("Localizable", "remote.offlineCard.subtitle", fallback: "Retrying automatically…")
      /// TV is unreachable
      public static let title = L10n.tr("Localizable", "remote.offlineCard.title", fallback: "TV is unreachable")
    }
    public enum PairCard {
      /// One-time setup. A code will appear on the TV.
      public static let subtitle = L10n.tr("Localizable", "remote.pairCard.subtitle", fallback: "One-time setup. A code will appear on the TV.")
      /// Pair with this TV
      public static let title = L10n.tr("Localizable", "remote.pairCard.title", fallback: "Pair with this TV")
    }
    public enum Tab {
      /// Apps
      public static let apps = L10n.tr("Localizable", "remote.tab.apps", fallback: "Apps")
      /// Keypad
      public static let keypad = L10n.tr("Localizable", "remote.tab.keypad", fallback: "Keypad")
      /// More
      public static let more = L10n.tr("Localizable", "remote.tab.more", fallback: "More")
      /// Type
      public static let type = L10n.tr("Localizable", "remote.tab.type", fallback: "Type")
    }
    public enum Typing {
      /// Enter
      public static let enter = L10n.tr("Localizable", "remote.typing.enter", fallback: "Enter")
      /// Send Enter to the TV
      public static let enterHelp = L10n.tr("Localizable", "remote.typing.enterHelp", fallback: "Send Enter to the TV")
      /// Open a search or text box on the TV, then type here. Letters appear on the TV as you type; Return sends Enter.
      public static let hint = L10n.tr("Localizable", "remote.typing.hint", fallback: "Open a search or text box on the TV, then type here. Letters appear on the TV as you type; Return sends Enter.")
      /// Type on TV…
      public static let placeholder = L10n.tr("Localizable", "remote.typing.placeholder", fallback: "Type on TV…")
    }
  }
  public enum Settings {
    /// Appearance
    public static let appearance = L10n.tr("Localizable", "settings.appearance", fallback: "Appearance")
    /// Clear History
    public static let clearHistory = L10n.tr("Localizable", "settings.clearHistory", fallback: "Clear History")
    /// Color theme
    public static let colorTheme = L10n.tr("Localizable", "settings.colorTheme", fallback: "Color theme")
    /// Forget all TVs except the current one?
    public static let confirmClear = L10n.tr("Localizable", "settings.confirmClear", fallback: "Forget all TVs except the current one?")
    /// Reset Google TV pairing?
    public static let confirmReset = L10n.tr("Localizable", "settings.confirmReset", fallback: "Reset Google TV pairing?")
    /// Connect automatically
    public static let connectAutomatically = L10n.tr("Localizable", "settings.connectAutomatically", fallback: "Connect automatically")
    /// Connection
    public static let connection = L10n.tr("Localizable", "settings.connection", fallback: "Connection")
    /// Custom color
    public static let customColor = L10n.tr("Localizable", "settings.customColor", fallback: "Custom color")
    /// Favorite: connects first
    public static let favoriteHelp = L10n.tr("Localizable", "settings.favoriteHelp", fallback: "Favorite: connects first")
    /// Forget this TV
    public static let forgetHelp = L10n.tr("Localizable", "settings.forgetHelp", fallback: "Forget this TV")
    /// Keyboard
    public static let keyboard = L10n.tr("Localizable", "settings.keyboard", fallback: "Keyboard")
    /// Launch at login
    public static let launchAtLogin = L10n.tr("Localizable", "settings.launchAtLogin", fallback: "Launch at login")
    /// Notifications
    public static let notifications = L10n.tr("Localizable", "settings.notifications", fallback: "Notifications")
    /// Deletes the pairing certificate from your Keychain. Every Google TV will show a new code to pair again.
    public static let resetMessage = L10n.tr("Localizable", "settings.resetMessage", fallback: "Deletes the pairing certificate from your Keychain. Every Google TV will show a new code to pair again.")
    /// Reset Pairing
    public static let resetPairing = L10n.tr("Localizable", "settings.resetPairing", fallback: "Reset Pairing")
    /// Retry offline TV every
    public static let retryEvery = L10n.tr("Localizable", "settings.retryEvery", fallback: "Retry offline TV every")
    /// Saved TVs
    public static let savedTVs = L10n.tr("Localizable", "settings.savedTVs", fallback: "Saved TVs")
    /// Startup
    public static let startup = L10n.tr("Localizable", "settings.startup", fallback: "Startup")
    public enum Keyboard {
      /// Backspace
      public static let backspace = L10n.tr("Localizable", "settings.keyboard.backspace", fallback: "Backspace")
      /// Navigate
      public static let navigate = L10n.tr("Localizable", "settings.keyboard.navigate", fallback: "Navigate")
      /// OK · Back
      public static let okBack = L10n.tr("Localizable", "settings.keyboard.okBack", fallback: "OK · Back")
      /// Play · Mute · Home
      public static let playMuteHome = L10n.tr("Localizable", "settings.keyboard.playMuteHome", fallback: "Play · Mute · Home")
      /// Volume
      public static let volume = L10n.tr("Localizable", "settings.keyboard.volume", fallback: "Volume")
    }
    public enum SavedTVs {
      /// TVs appear here after you connect to them.
      public static let empty = L10n.tr("Localizable", "settings.savedTVs.empty", fallback: "TVs appear here after you connect to them.")
    }
    public enum Tab {
      /// About
      public static let about = L10n.tr("Localizable", "settings.tab.about", fallback: "About")
      /// Settings
      public static let general = L10n.tr("Localizable", "settings.tab.general", fallback: "General")
      /// Look
      public static let look = L10n.tr("Localizable", "settings.tab.look", fallback: "Look")
      /// TVs
      public static let tvs = L10n.tr("Localizable", "settings.tab.tvs", fallback: "TVs")
    }
  }
  public enum Status {
    /// Connected
    public static let connected = L10n.tr("Localizable", "status.connected", fallback: "Connected")
    /// Connecting…
    public static let connecting = L10n.tr("Localizable", "status.connecting", fallback: "Connecting…")
    /// Connection status (header)
    public static let notConnected = L10n.tr("Localizable", "status.notConnected", fallback: "Not connected")
    /// Offline
    public static let offline = L10n.tr("Localizable", "status.offline", fallback: "Offline")
    /// Pairing required
    public static let pairingRequired = L10n.tr("Localizable", "status.pairingRequired", fallback: "Pairing required")
    /// Standby
    public static let standby = L10n.tr("Localizable", "status.standby", fallback: "Standby")
  }
  public enum Theme {
    /// Custom
    public static let custom = L10n.tr("Localizable", "theme.custom", fallback: "Custom")
    /// Forest
    public static let forest = L10n.tr("Localizable", "theme.forest", fallback: "Forest")
    /// Graphite
    public static let graphite = L10n.tr("Localizable", "theme.graphite", fallback: "Graphite")
    /// Ocean
    public static let ocean = L10n.tr("Localizable", "theme.ocean", fallback: "Ocean")
    /// Rose
    public static let rose = L10n.tr("Localizable", "theme.rose", fallback: "Rose")
    /// Sunset
    public static let sunset = L10n.tr("Localizable", "theme.sunset", fallback: "Sunset")
    /// TCL Red
    public static let tclRed = L10n.tr("Localizable", "theme.tclRed", fallback: "TCL Red")
    /// Themes and appearance
    public static let violet = L10n.tr("Localizable", "theme.violet", fallback: "Violet")
  }
  public enum Toast {
    /// Couldn't change login item: %@
    public static func loginItemFailed(_ p1: Any) -> String {
      return L10n.tr("Localizable", "toast.loginItemFailed", String(describing: p1), fallback: "Couldn't change login item: %@")
    }
    /// Opening %@…
    public static func opening(_ p1: Any) -> String {
      return L10n.tr("Localizable", "toast.opening", String(describing: p1), fallback: "Opening %@…")
    }
    /// Paired
    public static let paired = L10n.tr("Localizable", "toast.paired", fallback: "Paired")
    /// Pairing failed: %@
    public static func pairingFailed(_ p1: Any) -> String {
      return L10n.tr("Localizable", "toast.pairingFailed", String(describing: p1), fallback: "Pairing failed: %@")
    }
    /// Pairing reset. Google TVs will ask for a new code.
    public static let pairingReset = L10n.tr("Localizable", "toast.pairingReset", fallback: "Pairing reset. Google TVs will ask for a new code.")
    /// Toasts
    public static let reconnected = L10n.tr("Localizable", "toast.reconnected", fallback: "Reconnected")
    /// %@ isn't available on this TV
    public static func unsupported(_ p1: Any) -> String {
      return L10n.tr("Localizable", "toast.unsupported", String(describing: p1), fallback: "%@ isn't available on this TV")
    }
  }
  public enum Volume {
    /// Volume
    public static let label = L10n.tr("Localizable", "volume.label", fallback: "Volume")
    /// Volume bar
    public static let mute = L10n.tr("Localizable", "volume.mute", fallback: "Mute")
    /// Muted
    public static let muted = L10n.tr("Localizable", "volume.muted", fallback: "Muted")
    /// Unmute
    public static let unmute = L10n.tr("Localizable", "volume.unmute", fallback: "Unmute")
    /// %d of %d
    public static func value(_ p1: Int, _ p2: Int) -> String {
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
